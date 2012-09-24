# encoding: utf-8
# require File.expand_path(File.join(File.dirname(__FILE__),'workbook'))
# require File.expand_path(File.join(File.dirname(__FILE__),'worksheet'))
# require File.expand_path(File.join(File.dirname(__FILE__),'cell'))
# require File.expand_path(File.join(File.dirname(__FILE__),'color'))
require 'rubygems'
require 'nokogiri'

module RubyXL
module Writer
  class WorkbookWriter
    attr_accessor :dirpath, :filepath, :workbook

    def initialize(dirpath, wb)
      @dirpath = dirpath
      @workbook = wb
      @filepath = dirpath + '/xl/workbook.xml'
    end

    def write()
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.workbook('xmlns'=>"http://schemas.openxmlformats.org/spreadsheetml/2006/main",
        'xmlns:r'=>"http://schemas.openxmlformats.org/officeDocument/2006/relationships") {
          #attributes out of order here
          xml.fileVersion('appName'=>'xl', 'lastEdited'=>'4','lowestEdited'=>'4','rupBuild'=>'4505')
          #TODO following line - date 1904? check if mac only
          if @workbook.date1904.nil? || @workbook.date1904.to_s == ''
            xml.workbookPr('showInkAnnotation'=>'0', 'autoCompressPictures'=>'0')
          else
            xml.workbookPr('date1904'=>@workbook.date1904.to_s, 'showInkAnnotation'=>'0', 'autoCompressPictures'=>'0')
          end
          xml.bookViews {
            #attributes out of order here
            xml.workbookView('xWindow'=>'-20', 'yWindow'=>'-20',
              'windowWidth'=>'21600','windowHeight'=>'13340','tabRatio'=>'500')
          }
          xml.sheets {
            @workbook.worksheets.each_with_index do |sheet,i|
              j = (i+1).to_s
              xml.sheet('name'=>sheet.sheet_name, 'sheetId'=>j, 'r:id'=>'rId'+j)
            end
          }
          unless @workbook.external_links.nil?
            xml.externalReferences {
              n = @workbook.worksheets.size
              (n+1).upto(@workbook.external_links.size+n) do |id|
                xml.externalReference('r:id'=>"rId#{id}")
              end
            }
          end

          # nokogiri builder creates CDATA tag around content,
          # using .text creates "html safe" &lt; and &gt; in place of < and >
          # xml to hash method does not seem to function well for this particular piece of xml
          xml.cdata @workbook.defined_names.to_s

          #TODO see if this changes with formulas
          #attributes out of order here
          xml.calcPr('calcId'=>'130407', 'concurrentCalc'=>'0')
          xml.extLst {
            xml.ext('xmlns:mx'=>"http://schemas.microsoft.com/office/mac/excel/2008/main",
            'uri'=>"http://schemas.microsoft.com/office/mac/excel/2008/main") {
              xml['mx'].ArchID('Flags'=>'2')
            }
          }
        }
      end
      contents = builder.to_xml :encoding => 'UTF-8'
      contents = contents.gsub(/\n/u,'')
      contents = contents.gsub(/>(\s)+</u,'><')
      contents = contents.gsub(/<!\[CDATA\[(.*)\]\]>/u,'\1')
      contents = contents.sub(/<\?xml version=\"1.0\"\?>/u,'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+"\n")
      contents
    end
  end
end
end
