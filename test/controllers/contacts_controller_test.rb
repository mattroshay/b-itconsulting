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
    assert_equal "Veuillez confirmer que vous n'êtes pas un robot.", flash[:alert]
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

  test "should reject submission with valid recaptcha but missing required fields" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)

    assert_no_emails do
      post contacts_path, params: {
        contact_form: {
          first_name: "Test",
          last_name: "", # Missing required field
          email: "test@example.com",
          subject: "Test Subject",
          message: ""    # Missing required field
        }
      }
    end

    assert_response :unprocessable_entity
    assert_template :new
  end

  test "should reject submission with valid recaptcha but invalid email format" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)

    assert_no_emails do
      post contacts_path, params: {
        contact_form: {
          first_name: "Test",
          last_name: "User",
          email: "invalid-email-format", # Invalid email format
          subject: "Test Subject",
          message: "Test message content"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_template :new
  end

  test "should handle SMTP authentication error gracefully" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
    
    # Stub the mailer to raise an SMTP authentication error
    ContactMailer.stubs(:contact_email).raises(Net::SMTPAuthenticationError.new("Authentication failed"))

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
    assert_template :new
    assert_equal "Erreur lors de l'envoi du message. Veuillez réessayer plus tard.", flash[:alert]
  end

  test "should handle SMTP server busy error gracefully" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
    
    # Stub the mailer to raise an SMTP server busy error
    ContactMailer.stubs(:contact_email).raises(Net::SMTPServerBusy.new("Server busy"))

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
    assert_template :new
    assert_equal "Erreur lors de l'envoi du message. Veuillez réessayer plus tard.", flash[:alert]
  end

  test "should handle SMTP syntax error gracefully" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
    
    # Stub the mailer to raise an SMTP syntax error
    ContactMailer.stubs(:contact_email).raises(Net::SMTPSyntaxError.new("Syntax error"))

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
    assert_template :new
    assert_equal "Erreur lors de l'envoi du message. Veuillez réessayer plus tard.", flash[:alert]
  end

  test "should handle SMTP fatal error gracefully" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
    
    # Stub the mailer to raise an SMTP fatal error
    ContactMailer.stubs(:contact_email).raises(Net::SMTPFatalError.new("Fatal error"))

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
    assert_template :new
    assert_equal "Erreur lors de l'envoi du message. Veuillez réessayer plus tard.", flash[:alert]
  end

  test "should handle SMTP unknown error gracefully" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
    
    # Stub the mailer to raise an SMTP unknown error
    ContactMailer.stubs(:contact_email).raises(Net::SMTPUnknownError.new("Unknown error"))

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
    assert_template :new
    assert_equal "Erreur lors de l'envoi du message. Veuillez réessayer plus tard.", flash[:alert]
  end

  test "should handle SMTP connection timeout gracefully" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
    
    # Stub the mailer to raise a connection timeout error
    ContactMailer.stubs(:contact_email).raises(Net::OpenTimeout.new("Connection timeout"))

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
    assert_template :new
    assert_equal "Impossible de se connecter au serveur d'email. Veuillez réessayer plus tard.", flash[:alert]
  end

  test "should handle SMTP read timeout gracefully" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
    
    # Stub the mailer to raise a read timeout error
    ContactMailer.stubs(:contact_email).raises(Net::ReadTimeout.new("Read timeout"))

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
    assert_template :new
    assert_equal "Impossible de se connecter au serveur d'email. Veuillez réessayer plus tard.", flash[:alert]
  end

  test "should handle SMTP connection refused gracefully" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
    
    # Stub the mailer to raise a connection refused error
    ContactMailer.stubs(:contact_email).raises(Errno::ECONNREFUSED.new("Connection refused"))

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
    assert_template :new
    assert_equal "Impossible de se connecter au serveur d'email. Veuillez réessayer plus tard.", flash[:alert]
  end

  test "should handle SMTP connection timed out gracefully" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
    
    # Stub the mailer to raise a connection timed out error
    ContactMailer.stubs(:contact_email).raises(Errno::ETIMEDOUT.new("Connection timed out"))

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
    assert_template :new
    assert_equal "Impossible de se connecter au serveur d'email. Veuillez réessayer plus tard.", flash[:alert]
  end

  test "should handle unexpected standard error during email delivery gracefully" do
    # Stub reCAPTCHA verification to succeed
    ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
    
    # Stub the mailer to raise an unexpected error
    ContactMailer.stubs(:contact_email).raises(StandardError.new("Unexpected error"))

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
    assert_template :new
    assert_equal "Une erreur inattendue s'est produite. Veuillez réessayer.", flash[:alert]
  end
end
