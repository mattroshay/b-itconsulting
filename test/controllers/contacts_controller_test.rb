require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get contact_path
    assert_response :success
  end

  test "should reject submission without recaptcha" do
    # Stub reCAPTCHA verification to fail
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(false)

    post contacts_path, params: {
      contact_form: {
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        subject: "Test Subject",
        message: "Test message content"
      }
    }

    assert_response :unprocessable_entity
  end

  test "should send email with valid recaptcha" do
    # Stub reCAPTCHA verification
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)

    assert_emails 2 do
      post contacts_path, params: {
        contact_form: {
          first_name: "Test",
          last_name: "User",
          email: "test@example.com",
          subject: "Test Subject",
          message: "Test message content"
        }
      }
    end

    assert_redirected_to contact_path
  end
end
