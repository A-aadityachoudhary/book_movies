module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # 1. Fetch your Rails application session key name (defaults to _cine_book_session or similar)
      session_key = Rails.application.config.session_options[:key]
      
      # 2. Extract and decrypt the cookie payload safely
      session_data = cookies.encrypted[session_key]
      
      if session_data && session_data["warden.user.user.key"]
        # Devise stores user data as an array: [[user_id], "password_salt_hash"]
        user_id = session_data["warden.user.user.key"][0][0]
        verified_user = User.find_by(id: user_id)
        
        if verified_user
          return verified_user
        end
      end

      # Reject connection if the client is an unauthenticated guest user
      reject_unauthorized_connection
    end
  end
end