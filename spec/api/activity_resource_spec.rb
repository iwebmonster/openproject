require 'spec_helper'
require 'rack/test'

describe 'API v3 Activity resource' do
  include Rack::Test::Methods

  let(:current_user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:work_package) { FactoryGirl.create(:work_package, author: current_user, project: project) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:activity) { FactoryGirl.create(:work_package_journal, journable: work_package) }
  let(:model) { ::API::V3::Activities::ActivityModel.new(activity) }
  let(:representer) { ::API::V3::Activities::ActivityRepresenter.new(model) }

  describe '#get' do
    subject(:response) { last_response }

    context 'logged in user' do
      let(:get_path) { "/api/v3/activities/#{activity.id}" }
      before do
        allow(User).to receive(:current).and_return current_user
        member = FactoryGirl.build(:member, user: current_user, project: project)
        member.role_ids = [role.id]
        member.save!
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      xit 'should respond with correct activity' do
        expect(subject.body).to be_json_eql(representer.to_json)
      end

      context 'requesting nonexistent activity' do
        let(:get_path) { "/api/v3/activities/9999" }
        it 'should respond with 404' do
          expect(subject.status).to eq(404)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_found'.to_json).at_path('title')
        end
      end

      context 'requesting activity without sufficient permissions' do
        let(:another_project) { FactoryGirl.create(:project, is_public: false) }
        let(:another_work_package) { FactoryGirl.create(:work_package, project: another_project) }
        let(:another_activity) { FactoryGirl.create(:work_package_journal, journable: another_work_package) }
        let(:get_path) { "/api/v3/activities/#{another_activity.id}" }

        it 'should respond with 403' do
          expect(subject.status).to eq(403)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_authorized'.to_json).at_path('title')
        end
      end
    end

    context 'anonymous user' do
      let(:get_path) { "/api/v3/activities/#{activity.id}" }
      let(:project) { FactoryGirl.create(:project, is_public: true) }

      context 'when access for anonymous user is allowed' do
        before { get get_path }

        it 'should respond with 200' do
          expect(subject.status).to eq(200)
        end

        xit 'should respond with correct activity' do
          expect(subject.body).to be_json_eql(representer.to_json)
        end
      end

      context 'when access for anonymous user is not allowed' do
        before do
          Setting.login_required = 1
          get get_path
        end
        after { Setting.login_required = 0 }

        it 'should respond with 401' do
          expect(subject.status).to eq(401)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_authenticated'.to_json).at_path('title')
        end
      end
    end
  end
end
