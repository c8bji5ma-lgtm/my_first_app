require "rails_helper"

RSpec.describe "User authentication", type: :request do
  let(:password) { "password123" }

  def register_user(attributes = {})
    post user_registration_path, params: {
      user: { email: "new@example.com", password: password,
              password_confirmation: password }.merge(attributes)
    }
  end

  it "allows access to the sign-in and sign-up pages without authentication" do
    get new_user_session_path
    expect(response).to have_http_status(:ok)
    get new_user_registration_path
    expect(response).to have_http_status(:ok)
  end

  it "registers a user and redirects to the protected root" do
    expect { register_user }.to change(User, :count).by(1)
    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("new@example.com")
  end

  it "does not allow registration to grant admin privileges" do
    register_user(admin: true)
    expect(User.find_by!(email: "new@example.com").admin?).to be(false)
  end

  it "rejects invalid registration attributes" do
    expect { register_user(password_confirmation: "different") }.not_to change(User, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "signs in with valid credentials and redirects to the protected root" do
    user = create(:user, password: password)
    post user_session_path, params: { user: { email: user.email, password: password } }
    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(user.email)
  end

  it "rejects invalid login credentials" do
    user = create(:user)
    post user_session_path, params: { user: { email: user.email, password: "incorrect" } }
    expect(response).to have_http_status(:unprocessable_content)
    get root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "signs out via DELETE and prevents further protected access" do
    user = create(:user, password: password)
    post user_session_path, params: { user: { email: user.email, password: password } }
    delete destroy_user_session_path
    expect(response).to redirect_to(root_path)
    get root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "redirects unauthenticated visitors to sign-in" do
    get root_path
    expect(response).to redirect_to(new_user_session_path)
  end
end
