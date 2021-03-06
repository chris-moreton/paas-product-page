ENV['RACK_ENV'] = 'test'
ENV['DESKPRO_API_KEY'] = FAKE_DESKPRO_API_KEY
ENV['DESKPRO_ENDPOINT'] = FAKE_DESKPRO_ENDPOINT
ENV['DESKPRO_TEAM_ID'] = '1'

require 'rack/test'
require 'capybara/rspec'
require 'net/http'
Capybara.app = Rack::Builder.parse_file("config.ru").first

RSpec.describe "ContactUs", :type => :feature do

	include Rack::Test::Methods

	it "should submit the form successfully" do
		visit '/contact-us'
		fill_in('person_name', with: 'Jeff Jefferson')
		fill_in('person_email', with: 'jeff@test.gov.uk')
		fill_in('department_name', with: 'TestDept')
		fill_in('service_name', with: 'TestService')
		fill_in('message', with: 'Hello There')
		click_button('contact-submit')
		all('.error-message').each do |err|
			expect(err.text).to be_empty, "Did not expect to see any validation errors but got: #{err.text}"
		end
		all('.error-summary .err').each do |err|
			expect(err.text).to be_empty, "Did not expect to see a summary of errors but got: #{err.text}"
		end
		expect(page.status_code).to eq(200)
	end

	it "should require person_name field" do
		visit '/contact-us'
		fill_in('person_email', with: 'jeff@test.gov.uk')
		fill_in('department_name', with: 'TestDept')
		fill_in('service_name', with: 'TestService')
		fill_in('message', with: 'Hello There')
		click_button('contact-submit')
		expect(page.first('.form-group--person_name .error-message').text).not_to be_empty
		expect(page.status_code).to eq(400)
	end

	it "should require person_email field" do
		visit '/contact-us'
		fill_in('person_name', with: 'jeff')
		fill_in('department_name', with: 'TestDept')
		fill_in('service_name', with: 'TestService')
		fill_in('message', with: 'Hello There')
		click_button('contact-submit')
		expect(page.first('.form-group--person_email .error-message').text).not_to be_empty
		expect(page.status_code).to eq(400)
	end

	it "should require a valid email for person_email" do
		visit '/contact-us'
		fill_in('person_name', with: 'jeff')
		fill_in('person_email', with: 'not-an-email')
		fill_in('department_name', with: 'TestDept')
		fill_in('service_name', with: 'TestService')
		fill_in('message', with: 'Hello There')
		click_button('contact-submit')
		expect(page.first('.form-group--person_email .error-message').text).not_to be_empty
		expect(page.status_code).to eq(400)
	end

	it "escapes XSS from the query string" do
		visit '/contact-us?person_name=%22%3E%3Cscript%3Ealert(%27%27)%3C/script%3E'
		# If the attack works, the HTML will have broken out of the value. If the attack failed, the HTML
		# will be inside the value attribute.
		expect(page.first('.form-group--person_name input').value).to eq("\"><script>alert('')</script>")
	end

	it "should provide the correct Content-Security-Policy" do
		visit '/contact-us'
		expect(page.status_code).to eq(200)
		expect(page.response_headers['Content-Security-Policy']).to eq("connect-src 'self' www.google-analytics.com; default-src none; font-src 'self' data:; frame-src 'self'; img-src 'self' www.google-analytics.com; media-src 'self'; object-src 'self'; script-src 'self' www.google-analytics.com; style-src 'self' 'unsafe-inline'")
	end

end
