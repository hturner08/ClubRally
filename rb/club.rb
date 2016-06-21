def clubincludesuser? (club)
    if club.members.include? session[:username] or club.board.include? session[:username] or club.head.include? session[:username]
        return true
    else
        return false
    end
end

def approved? (club)
    return club.approved
end

def illegal_characters?(string)
    if string.include?("/") or string.include?("[") or string.include?("]")
        return true
    else
        return false
    end
end

$categories = [{:name => "STEM", :icon => "flask", :img => "stem.jpeg"}, {:name => "Politics and Debate", :icon => "balance-scale", :img => "publicspeaking.jpg"}, {:name => "Art", :icon => "paint-brush", :img => "art.jpeg"}, {:name => "Non Sibi", :icon => "hand-peace-o", :img => "nonsibi.jpg"}, {:name => "Publications", :icon => "file-text", :img => "books.jpeg"}, {:name => "Athletics", :icon => "futbol-o", :img => "athletics.jpeg"}, {:name => "Music", :icon => "music", :img => 
"music.jpeg"}, {:name => "Academics", :icon => "graduation-cap", :img => "academics.jpeg"}]

get "/dashboard/category/:category" do
    $path = "/dashboard/category/#{params[:category]}"
    protected!
    startup
    #if category exists
    if $categories.any? {|h| h[:name] == params[:category]}
        @category = $categories.find {|h| h[:name] == params[:category] }
        @clubs = Club.where(:tag => params[:category], :approved => true)
        puts "category: #{@category}"
        partial :dashboard_categories, :layout => false
    else
        redirect "/404"
    end
end

get "/addboard/:club/:member" do
    if Club.all.exists?(:name => params[:club]) and User.all.exists?(:email => params[:member])
        club = Club.find_by(name: params[:club])
        if club.head.include?(session[:username]) and club.members.include?(params[:member]) and !club.board.include?(params[:member]) and !club.head.include?(params[:member]) and approved?(club)
            club.board << params[:member]
            club.members.delete(params[:member])
            club.save
            club.head.each do |email|
                head = User.find_by(email: email)
                send_notification(head, "plus", "Board updated", "#{params[:member]} added to board of #{club.name}", Time.new.to_i)
            end
            new_board = User.find_by(email: params[:member])
            send_notification(new_board, "plus", "Board updated", "You've been added to board of #{club.name}", Time.new.to_i)
            redirect "/dashboard/club/#{params[:club]}"
        else
            redirect "/404"
        end
    else
        redirect "/404"
    end
end

get "/dashboard/createclub" do
    $path = "/dashboard/createclub"
    protected!
    startup
    partial :dashboard_createclub, :layout => false
end

post "/createclub" do

    if params[:name].length > 45
        flash[:error] = "Name of your club is too long"
        redirect "/dashboard/createclub"
    elsif params[:description].length > 55
        flash[:error] = "Your club description is too long"
        redirect "/dashboard/createclub"
    elsif params[:name].length == 0 or params[:description].length == 0 or params[:tags] == "Club Category:" or params[:location].length == 0
        flash[:error] = "Please fill out all fields"
        redirect "/dashboard/createclub"
    elsif illegal_characters?(params[:name])
        flash[:error] = "The name of your club cannot contain '/', '[', or ']'"
        redirect "/dashboard/createclub"
    elsif Club.all.exists?(:name => params[:name])
        flash[:error] = "A club with that name already exists"
        redirect "/dashboard/createclub"
    else
        nomeeting = true
        if params[:nomeeting].nil?
            nomeeting = false
        end
        if params[:img].blank?
            Club.create(:name => params[:name], :description => params[:description], :img => "/default/default.png", :head => [session[:username]], :board => [], :members => [], :meetingtime => "#{params[:weekday]}, #{params[:time]}", :location => params[:location], :tag => params[:tags], :approved => false, :nomeeting => nomeeting)
        else
            @filename = params[:img][:filename]
            file = params[:img][:tempfile]

            File.open("./public/upload/#{@filename}", 'wb') do |f|
                f.write(file.read)
            end
    
            Club.create(:name => params[:name], :description => params[:description], :img => @filename, :head => [session[:username]], :board => [], :members => [], :meetingtime => "#{params[:weekday]}, #{params[:time]}", :location => params[:location], :tag => params[:tags], :approved => false, :nomeeting => nomeeting)
        end

        clubname = params[:name]
        if params[:name].include?(' ')
            clubname = params[:name].gsub!(' ','%20')
        end

        Admin.all.each do |admin|
            send_mail(admin.email, "Approve club", "Approve #{params[:name]}, created by #{session[:username]}? If so, go to http://clubrally.herokuapp.com/approve/#{clubname}. If not go to http://clubrally.herokuapp.com/dapprove/#{clubname}")
        end

        user = User.find_by(:email => session[:username])
        user.clubs << params[:name]
        user.save

        redirect "/dashboard/home"
    end

end

post "/updateimage" do
    if !params[:img].blank?
        @filename = params[:img][:filename]
        file = params[:img][:tempfile]

        File.open("./public/upload/#{@filename}", 'wb') do |f|
            f.write(file.read)
        end
        club = Club.find_by(name: params[:club])
        club.img = @filename
        club.save
    end
    redirect "/dashboard/club/#{params[:club]}"
end

post "/updateheads" do
    if params[:coheads].nil?
        flash[:error] = "You need to have at least one co-head"
        redirect "/dashboard/club/#{params[:club]}?hidden=false"
    elsif params[:coheads].length > 2
        flash[:error] = "You can only have 2 co-heads"
        redirect "/dashboard/club/#{params[:club]}?hidden=false"
    else
        timestamp = Time.new.to_i
        club = Club.find_by(name: params[:club])
        club.head.each do |member|
            if !params[:coheads].include?(member)
                send_notification(User.find_by(:email => member), "frown", "Co-heads updated", "You are no longer a co-head for #{club.name}", timestamp)
            end
        end
        club.head.clear
        params[:coheads].each do |member|
            club.head << member
            if club.members.include?(member)
                club.members.delete(member)
                send_notification(User.find_by(:email => member), "plus", "Co-heads updated", "You're now a co-head for #{club.name}", timestamp)
            elsif club.board.include?(member)
                club.board.delete(member)
                send_notification(User.find_by(:email => member), "plus", "Co-heads updated", "You're now a co-head for #{club.name}", timestamp)
            end
        end
        club.save
        redirect "/dashboard/club/#{params[:club]}"
    end
end

post "/editclub" do
    if params[:description].length > 55
        flash[:error] = "Your club description is too long"
        redirect "/edit/#{params[:name]}"
    elsif params[:description].length == 0 or params[:location].length == 0
        flash[:error] = "Please fill out all fields"
        redirect "/edit/#{params[:name]}"
    else
        club = Club.find_by(name: params[:name])
        nomeeting = true
        if params[:nomeeting].nil?
            nomeeting = false
        else
            allmembers = club.head + club.board + club.members
            allmembers.each do |member|
                user = User.find_by(:email => member)
                user.notifications.delete_if { |h| h[:title] == club.name}
                user.save
            end
        end
        club.description = params[:description]
        club.meetingtime = "#{params[:weekday]}, #{params[:time]}"
        club.location = params[:location]
        club.tag = params[:tags]
        club.nomeeting = nomeeting
        club.save

        user = User.find_by(:email => session[:username])
        if comingup?(club) and !club.nomeeting and user.notifications.any? { |h| h[:title] == params[:name] }
            user.notifications.delete_if { |h| h[:title] == club.name}
            user.save
            send_notification(user, "clock-o", club.name, "#{club.meetingtime}, #{club.location}", get_club_time(club).to_i)
        end

        redirect "/dashboard/club/#{params[:name]}"
    end
end

get "/dashboard/club/:club" do
    $path = "/dashboard/club/#{params[:club]}"
    protected!
    startup
    if Club.all.exists?(:name => params[:club])
        @club = Club.find_by(name: params[:club])
        if approved?(@club)
            @people = ""
            @club.members.each do |member|
                @people << "#{member};"
            end
            @club.board.each do |member|
                @people << "#{member};" unless member == session[:username]
            end
            @club.head.each do |member|
                @people << "#{member};" unless member == session[:username]
            end
        
            @people = @people[0...-1]
            @list = "#{@people}?subject=#{@club.name}"
        
            partial :dashboard_club, :layout => false
        else
            redirect "/404"
        end
    else
        redirect "/404"
    end
end

get "/join/:club" do
    $path = "/join/#{params[:club]}"
    protected!
    if Club.all.exists?(:name => params[:club])
        club = Club.find_by(name: params[:club])
        if approved?(club) and !club.members.include?(session[:username])
            club.members << session[:username]
            club.save
            club.head.each do |email|
                head = User.find_by(email: email)
                send_notification(head, "user", "New Member", "#{session[:username]} joined #{club.name}", Time.new.to_i)
            end
            club.board.each do |email|
                board = User.find_by(email: email)
                send_notification(board, "user", "New Member", "#{session[:username]} joined #{club.name}", Time.new.to_i)
            end

            user = User.find_by(email: session[:username])
            user.clubs << params[:club]
            user.save

            redirect "/dashboard/home"
        else
            redirect "/404"
        end
    else
        redirect "/404"
    end
end

get "/leave/:club" do
    $path = "/leave/#{params[:club]}"
    protected!
    if Club.all.exists?(:name => params[:club])
        club = Club.find_by(name: params[:club])
        if approved?(club) and (club.members.include?(session[:username]) or club.board.include?(session[:username]))
            if club.members.include?(session[:username])
                club.members.delete(session[:username])
            else
                club.board.delete(session[:username])
            end
            club.save
            club.head.each do |email|
                head = User.find_by(email: email)
                send_notification(head, "sign-out", "Member left", "#{session[:username]} left #{club.name}", Time.new.to_i)
            end
            club.board.each do |email|
                board = User.find_by(email: email)
                send_notification(board, "sign-out", "Member left", "#{session[:username]} left #{club.name}", Time.new.to_i)
            end

            user = User.find_by(email: session[:username])
            user.clubs.delete(params[:club])
            user.save

            redirect "/dashboard/home"
        else
            redirect "/404"
        end
    else
        redirect "/404"
    end
end

get "/delete/:club" do
    $path = "/delete/#{params[:club]}"
    protected!
    if Club.all.exists?(:name => params[:club])
        club = Club.find_by(name: params[:club])
        allmembers = club.head + club.board + club.members
        allmembers.each do |member|
            user = User.find_by(:email => member)
            user.notifications.delete_if { |h| h[:title] == club.name}
            user.clubs.delete(params[:club])
            user.save
        end
        if approved?(club) and club.head.include? session[:username]
            Club.where(name: params[:club]).destroy_all
        else
            redirect "/404"
        end
        redirect "/dashboard/home"
    else
        redirect "/404"
    end
end

get "/edit/:club" do
    $path = "/edit/#{params[:club]}"
    protected!
    user = User.find_by(email: session[:username]).email
    if Club.all.exists?(:name => params[:club])
        @club = Club.find_by(name: params[:club])
        if approved?(@club) and @club.head.include? user
            partial :dashboard_edit, :layout => false
        else
            redirect "/404"
        end
    else
        redirect "/404"
    end
end

get "/approve/:club" do
    if Admin.all.exists?(:email => session[:username]) and Club.all.exists?(:name => params[:club])
        club = Club.find_by(name: params[:club])
        if club.approved == false
            club.approved = true
            club.save

            club.head.each do |email|
                head = User.find_by(email: email)
                send_notification(head, "thumbs-up", "Approved!", "Your request to create #{club.name} has been approved", Time.new.to_i)
                send_mail(email, "Approved!", "Your request to create #{club.name} has been approved")
            end
        end
        redirect "/dashboard/home"
    else
        redirect "/404"
    end
end

get "/dapprove/:club" do
    if Admin.all.exists?(:email => session[:username]) and Club.all.exists?(:name => params[:club])
        club = Club.find_by(name: params[:club])
        unless club.approved == true
            Club.where(name: params[:club]).destroy_all
            club.head.each do |email|
                head = User.find_by(email: email)
                send_notification(head, "thumbs-down", "Denied request", "Unfortunately, your request to create #{club.name} has been denied", Time.new.to_i)
                send_mail(email, "Denied request", "Unfortunately, your request to create #{club.name} has been denied")
            end

            redirect "/dashboard/home"
        else
            redirect "/404"
        end
    else
        redirect "/404"
    end
end
