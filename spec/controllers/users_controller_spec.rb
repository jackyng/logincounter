require 'spec_helper'

describe UsersController do
	context "Adding a new user" do
		it "should get errCode 1 and count 1 with valid credentials" do
			post :add, { format: 'json', username: "pika", password: "chu" }
			response.should be_success

			response_body = JSON.parse response.body
			response_body.should have(2).items

			response_body.should include('errCode')
			response_body['errCode'].should == 1

			response_body.should include('count')
			response_body['errCode'].should == 1
		end

		it "should get errCode -3 with an invalid username and a valid password" do
			post :add, { format: 'json', username: "g"*150, password: "teehee" }
			response.should be_success

			response_body = JSON.parse response.body
			response_body.should have(1).item

			response_body.should include('errCode')
			response_body['errCode'].should == -3
		end

		it "should get errCode -2 with an username that already exists" do
			post :add, { format: 'json', username: "top", password: "gear" }
			post :add, { format: 'json', username: "top", password: "gear" }
			response.should be_success

			response_body = JSON.parse response.body
			response_body.should have(1).item

			response_body.should include('errCode')
			response_body['errCode'].should == -2
		end

		it "should get errCode -4 with a valid username and an invalid password" do
			post :add, { format: 'json', username: "bspace", password: "g"*150 }
			response.should be_success

			response_body = JSON.parse response.body
			response_body.should have(1).item

			response_body.should include('errCode')
			response_body['errCode'].should == -4
		end
	end

	context "Logging in" do
		it "should get errCode 1 and count incremented with valid credentials" do
			post :add, { format: 'json', username: "red", password: "box" }

			post :login, { format: 'json', username: "red", password: "box" }
			response.should be_success

			response_body = JSON.parse response.body
			response_body.should have(2).item

			response_body.should include('errCode')
			response_body.should include('count')
			response_body['errCode'].should == 1

			expect {
				post :login, { format: 'json', username: "red", password: "box" }
			}.to change { JSON.parse(response.body)['count'] }.by(1)
		end

		it "should get errCode -1 with invalid credentials" do
			post :login, { format: 'json', username: "blue", password: "print" }
			response.should be_success

			response_body = JSON.parse response.body
			response_body.should have(1).item

			response_body.should include('errCode')
			response_body['errCode'].should == -1
		end
	end
end