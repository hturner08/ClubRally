$path = "/dashboard/home"
$error = nil
$register_error = nil

helpers do
  
    def login?
        if session[:username].nil?
            return false
        else
            return true
        end
    end
  
    def username
        return session[:username]
    end
  
    def protected!
        if login? == false
             redirect "/login"
        end
    end
end

def verified? (user)
    return user.verified
end

get "/login" do
    if login?
        redirect $path
    end
    partial :signin, :layout => false
end

get "/register" do
    if login?
        redirect $path
    end
    partial :signup, :layout => false
end

get "/logout" do
    session[:username] = nil
    redirect "/"
end

get "/verify/:code" do
    if User.all.exists?(:verification_code => params[:code])
        user = User.find_by(verification_code: params[:code])
        user.verified = true
        user.save
        session[:username] = user.email
        redirect "/dashboard/home"
    else
        redirect "/404"
    end
end

post "/secureregister" do
    if User.all.exists?(:email => params[:email])
        $register_error = "That email is already in use."
        redirect "/register"
    elsif not params[:email].include? "@" or params[:email].slice(params[:email].index("@")..-1) != "@andover.edu"
        $register_error = "Enter an Andover email"
        redirect "/register"
    else
        password_salt = BCrypt::Engine.generate_salt
        password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)
        verify = "#{params[:email]}#{SecureRandom.hex}"
        User.create(:salt => password_salt, :passwordhash => password_hash, :email => params[:email], :verified => false, :verification_code => verify)
        send_mail(params[:email], "Verify your email address", "Thank you for signing up for Club Rally. Go to http://clubrally.herokuapp.com/verify/#{verify} to activate your account")
        $register_error = nil
        redirect "/verify"
    end
end

post "/secureauth" do
    if User.all.exists?(:email => params[:email])
        user = User.find_by(email: params[:email])
        puts "Verified: #{user.verified}"
        if not verified?(user)
            $error = "Verify your email"
            redirect "/login"
        else
            if user.passwordhash == BCrypt::Engine.hash_secret(params[:password], user.salt)
                session[:username] = params[:email]
                session.options[:expire_after] = 2592000 unless params['remember'].nil?
                $error = nil
                redirect $path
            else
                $error = "That password is incorrect."
                redirect "/login"
            end
        end
    else
        $error = "That email isn't registered."
        redirect "/login"
    end
end

def send_mail(to, subject, message)
  RestClient.post "https://api:key-45703f166fb8da3edba6d07255354e50"\
  "@api.mailgun.net/v3/sandboxab76c7df21e445c3a397e45fc18fbf07.mailgun.org/messages",
    :from => "Mailgun Sandbox <postmaster@sandboxab76c7df21e445c3a397e45fc18fbf07.mailgun.org>",
    :to => "<#{to}>",
    :subject => subject,
    :text => message
end
    
