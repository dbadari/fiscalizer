class Fiscalizer
  module Serializers
    class Base
      include Constants

      def initialize(object, private_key, public_key, demo)
        @object = object
        @private_key = private_key
        @public_key = public_key
        @demo = demo
      end

      attr_reader :object, :private_key, :public_key, :demo

      def call
        sign_xml
      end

      private

      def sign_xml
        document = Xmldsig_fiscalizer::SignedDocument.new(xml_with_soap_envelope.doc.root.to_xml)
        signed_xml = document.sign(private_key)
        signed_xml.sub!('<?xml version="1.0"?>', '')
        signed_xml = signed_xml.gsub(/^$\n/, '')
        object.generated_xml = signed_xml
        signed_xml
      end

      def xml_with_soap_envelope
        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml['soapenv'].Envelope('xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/') do
            xml['soapenv'].Body do
              xml << raw_xml.doc.root.to_xml
            end
          end
        end
      end

      def root_hash
        {
          'xmlns:tns' => TNS,
          'xmlns:xsi' => XSI,
          'xsi:schemaLocation' => SCHEMA_LOCATION,
          'Id' => message_id
        }
      end

      def add_header(xml)
        xml['tns'].Zaglavlje do
          xml['tns'].IdPoruke object.uuid
          xml['tns'].DatumVrijeme object.time_sent_str
        end
      end

      def add_signature(xml)
        Serializers::Signature.new(xml, "##{message_id}", public_key, cert_issuer).call
      end

      def cert_issuer
        demo ? DEMO_CERT_ISSUER : PROD_CERT_ISSUER
      end
    end
  end
end
