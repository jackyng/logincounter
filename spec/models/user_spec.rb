require 'spec_helper'
require 'user'

describe "New User" do
	subject { User.new }
	it { should respond_to(:username) }
	it { should respond_to(:password) }
	it { should respond_to(:count) }

	context 'with a valid username' do
		let(:newuser) { User.new }
		before { newuser.username = "team" }

		it 'is valid with a non-empty password' do
			newuser.password = "rocket"
			newuser.should be_valid
		end

		it 'is valid with no password' do
			newuser.should be_valid
		end

		it 'is valid with an empty password' do
			newuser.password = ""
			newuser.should be_valid
		end

		it 'is not valid with a password that has more than 128 characters' do
			newuser.password = "g"*150
			newuser.should_not be_valid
		end
	end

	context 'with a valid password' do
		let(:newuser) { User.new }
		before { newuser.password = "sword" }

		it 'is valid with a non-empty username' do
			newuser.username = "master"
			newuser.should be_valid
		end

		it 'is not valid to have no username' do
			newuser.should_not be_valid
		end

		it 'is not valid to have a blank username' do
			newuser.username = ""
			newuser.should_not be_valid
		end

		it 'is not valid with an username that has more than 128 characters' do
			newuser.username = "g"*150
			newuser.should_not be_valid
		end

		it 'is not valid with an username that already exists' do
			anouser = User.create(username: "kokori", password: "shield", count: 1)
			newuser.username = "kokori"
			newuser.should_not be_valid
		end
	end
end
