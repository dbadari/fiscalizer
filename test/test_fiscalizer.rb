require "test/unit"
require "fiscalizer"
require 'nokogiri'
require 'openssl'

class FiscalizerTest < Test::Unit::TestCase
	# Configure 
	KEY_PUBLIC_PATH = "/test/assets/fiskal1.cert"
	KEY_PRIVATE_PATH = "/test/assets/privateKey.key"
	CERTIFICATE_PATH = "/test/assets/democacert.pem"
	CERTIFICATE_P12_PATH = "/test/assets/fiskal1.pfx"
	URL_FISKAL = "https://cistest.apis-it.hr:8449/FiskalizacijaServiceTest"
	CER_ISSUED = "OU=DEMO,O=FINA,C=HR"
	PASSWORD = "12345678"
	# Use P12
	EXPORTED_KEYS = true
	# Test specific info
	UUID = "ca996cc7-fcc3-4c50-961b-40c8b875a5e8"
	ECHO = "This is a simple test..."
	# Personal information
	PIN = "00123456789" 
	PIN_OPERATOR = "00000000000"

	def test_initialization
		# Manual build
		fiscal = Fiscalizer.new

		# Populate
		fiscal.url = "www.somewhere.com"
		fiscal.key_public_path  = "path/to/my/cert.pem"
		fiscal.key_private_path = "path/to/my/cert.cer"

		# Test
		assert_equal "www.somewhere.com", 	fiscal.url, 				"Manual URL assignment"
		assert_equal "path/to/my/cert.pem", fiscal.key_public_path,		"Manual public certificate location assignment"
		assert_equal "path/to/my/cert.cer", fiscal.key_private_path,	"Manual private certificate location assignment"

		# Automatic Build
		fiscal = nil
		fiscal = Fiscalizer.new url: "www.somewhere.com", 
								key_public_path: "path/to/my/cert.pem", 
								key_private_path: "path/to/my/cert.cer"

		# Test
		assert_equal "www.somewhere.com", 	fiscal.url, 				"Automatic URL assignment"
		assert_equal "path/to/my/cert.pem", fiscal.key_public_path,		"Automatic public certificate location assignment"
		assert_equal "path/to/my/cert.cer", fiscal.key_private_path,	"Automatic private certificate location assignment"
	end # fiscal_ruby_test

	def test_echo
		fiscal = nil
		if EXPORTED_KEYS
			fiscal = Fiscalizer.new url: URL_FISKAL, 
									key_public_path: KEY_PUBLIC_PATH,
									key_private_path: KEY_PRIVATE_PATH,
									certificate_path: CERTIFICATE_PATH,
									certificate_issued_by: CER_ISSUED
		else
			fiscal = Fiscalizer.new url: URL_FISKAL,
									certificate_path: CERTIFICATE_PATH,
									certificate_p12_path: CERTIFICATE_P12_PATH,
									certificate_issued_by: CER_ISSUED,
									password: PASSWORD
		end
		echo = fiscal.echo text: ECHO
		assert_equal ECHO, echo.response, "Echo response message does not match sent message"
		assert echo.echo?, "Automatic echo check failed"
	end # test_echo

	def test_office
		# -- Here Be Dragons --
		fiscal = nil
		if EXPORTED_KEYS
			fiscal = Fiscalizer.new url: URL_FISKAL, 
									key_public_path: KEY_PUBLIC_PATH,
									key_private_path: KEY_PRIVATE_PATH,
									certificate_path: CERTIFICATE_PATH,
									certificate_issued_by: CER_ISSUED
		else
			fiscal = Fiscalizer.new url: URL_FISKAL,
									certificate_path: CERTIFICATE_PATH,
									certificate_p12_path: CERTIFICATE_P12_PATH,
									certificate_issued_by: CER_ISSUED,
									password: PASSWORD
		end

		assert fiscal!=nil, "Failed to initialize"
		# Generate invoice
		office = fiscal.office 	uuid: UUID,
								time_sent: Time.now,
								pin: PIN,
								office_label: "Poslovnica1",
								adress_street_name: "Somewhere",
								adress_house_num: "42",
								adress_house_num_addendum: "AD",
								adress_post_num: "10000",
								adress_settlement: "Block 25-C",
								adress_township: "Vogsphere",
								adress_other: nil,
								office_time: "Pon-Pet: 8:00-16:00",
								take_effect_date: Time.now + 3600 * 24 * 7,
								closure_mark: nil,
								specific_purpose: nil
		assert !office.errors?, "Returned an error"
		assert office.uuid != nil, "'UUID' was not returned"
		assert office.processed_at != nil, "'Processed at' was not returned"
	end # test_office

	def test_office_object
		# -- Here Be Dragons --
		fiscal = nil
		if EXPORTED_KEYS
			fiscal = Fiscalizer.new url: URL_FISKAL, 
									key_public_path: KEY_PUBLIC_PATH,
									key_private_path: KEY_PRIVATE_PATH,
									certificate_path: CERTIFICATE_PATH,
									certificate_issued_by: CER_ISSUED
		else
			fiscal = Fiscalizer.new url: URL_FISKAL,
									certificate_path: CERTIFICATE_PATH,
									certificate_p12_path: CERTIFICATE_P12_PATH,
									certificate_issued_by: CER_ISSUED,
									password: PASSWORD
		end

		# Generate office
		office = Fiscalizer::Office.new
		office.uuid = UUID
		office.time_sent = Time.now
		office.pin = PIN
		office.office_label = "Poslovnica1"
		office.adress_street_name = "Somewhere"
		office.adress_house_num = "42"
		office.adress_house_num_addendum = "AD"
		office.adress_post_num = "10000"
		office.adress_settlement = "Block 25-C"
		office.adress_township = "Vogsphere"
		office.adress_other = nil
		office.office_time = "Pon-Pet: 8:00-16:00"
		office.take_effect_date = Time.now + 3600 * 24 * 7
		office.closure_mark = nil
		office.specific_purpose = nil

		# Generate office
		office_response = fiscal.fiscalize_office office

		if office_response.errors?
			puts "There were some nasty errors!"
			office_response.errors.each do |error_code, error_message|
				puts "	" + error_code + " : " + error_message
			end
		end

		assert !office_response.errors?, "Returned an error"
		assert office_response.uuid != nil, "'UUID' was not returned"
		assert office_response.processed_at != nil, "'Processed at' was not returned"
	end # test_office_object

	def test_invoice
		# -- Here Be Dragons --
		fiscal = nil
		if EXPORTED_KEYS
			fiscal = Fiscalizer.new url: URL_FISKAL, 
									key_public_path: KEY_PUBLIC_PATH,
									key_private_path: KEY_PRIVATE_PATH,
									certificate_path: CERTIFICATE_PATH,
									certificate_issued_by: CER_ISSUED
		else
			fiscal = Fiscalizer.new url: URL_FISKAL,
									certificate_path: CERTIFICATE_PATH,
									certificate_p12_path: CERTIFICATE_P12_PATH,
									certificate_issued_by: CER_ISSUED,
									password: PASSWORD
		end
		# Generate taxes
		taxes_vat = []
		taxes_spending = []
		taxes_other = []
		(0..5).each do |i|
			tax = Fiscalizer::Tax.new
			tax.base = rand(10000 * 100).to_f / 100.0
			tax.rate = rand(100 * 100).to_f / 100.0
			taxes_vat << tax
		end
		(0..5).each do |i|
			tax = Fiscalizer::Tax.new
			tax.base = rand(10000 * 100).to_f / 100.0
			tax.rate = rand(100 * 100).to_f / 100.0
			taxes_spending << tax
		end
		(0..5).each do |i|
			tax = Fiscalizer::Tax.new
			tax.base = rand(10000 * 100).to_f / 100.0
			tax.rate = rand(100 * 100).to_f / 100.0
			tax.name = "My Test Tax #{i}"
			taxes_other << tax
		end
		# Generate invoice
		invoice = fiscal.invoice 	uuid: UUID,
									time_sent: Time.now,
									pin: PIN,
									in_vat_system: true,
									time_issued: Time.now - 3600,
									consistance_mark: "P",
									issued_number: "1",
									issued_office: "Pm2",
									issued_machine: "3",
									tax_vat: taxes_vat,
									tax_spending: taxes_spending,
									tax_other: taxes_other,
									payment_method: "g",
									operator_pin: PIN_OPERATOR,
									subsequent_delivery: false,
									value_non_taxable: 200.0

		assert !invoice.errors?, "Returned an error"
		assert invoice.uuid != nil, "'UUID' was not returned"
		assert invoice.processed_at != nil, "'Processed at' was not returned"
		assert invoice.unique_identifier != nil, "Uniqe Identifier (JIR) was not returned"
	end # test_invoice

end # FiscalizerRubyTest