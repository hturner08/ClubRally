def clubincludesuser? (club)
    if club.members.include? session[:username] or club.board.include? session[:username] or club.head.include? session[:username]
        return true
    else
        return false
    end
end

get "/addboard/:club/:member" do
    if Club.all.exists?(:name => params[:club]) and User.all.exists?(:email => params[:member])
        club = Club.find_by(name: params[:club])
        if club.head.include?(session[:username]) and club.members.include?(params[:member]) and !club.board.include?(params[:member]) and !club.head.include?(params[:member])
            club.board << params[:member]
            club.members.delete(params[:member])
            club.save
            club.head.each do |email|
                head = User.find_by(email: email)
                head.notifications.push({:type => "plus", :title => "Board updated", :description => "#{params[:member]} added to board of #{club.name}", :id => head.notification_id})
                head.notification_id += 1
                head.save
            end
            new_board = User.find_by(email: params[:member])
            new_board.notifications.push({:type => "plus", :title => "Board updated", :description => "You've been added to board of #{club.name}", :id => new_board.notification_id})
            new_board.notification_id += 1
            new_board.save
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
    Club.create(:name => params[:name], :description => params[:description], :img => params[:img], :head => [session[:username]], :board => [], :members => [], :meetingtime => "#{params[:weekday]}, #{params[:time]}", :location => params[:location])
    redirect "/dashboard/home"
end

post "/editclub" do
    club = Club.find_by(name: params[:name])
    club.description = params[:description]
    club.img = params[:img]
    club.meetingtime = "#{params[:weekday]}, #{params[:time]}"
    club.location = params[:location]
    club.save
    redirect "/dashboard/home"
end

get "/dashboard/club/:club" do
    $path = "/dashboard/club/#{params[:club]}"
    protected!
    startup
    if Club.all.exists?(:name => params[:club])
        @club = Club.find_by(name: params[:club])
        people = "&cc="
        @club.members.each do |member|
            people << "#{member};"
        end
        @club.board.each do |member|
            people << "#{member};"
        end
        @list = "mailto:#{session[:username]}?subject=#{@club.name}"
        if @club.members.length > 0
            @list << people
        end
        
        partial :dashboard_club, :layout => false
    else
        redirect "/404"
    end
end

get "/join/:club" do
    $path = "/join/#{params[:club]}"
    protected!
    if Club.all.exists?(:name => params[:club])
        club = Club.find_by(name: params[:club])
        club.members << session[:username]
        club.save
        club.head.each do |email|
            head = User.find_by(email: email)
            head.notifications.push({:type => "user", :title => "New Member", :description => "#{session[:username]} joined #{club.name}", :id => head.notification_id})
            head.notification_id += 1
            head.save
        end
        redirect "/dashboard/home"
    else
        redirect "/404"
    end
end

get "/leave/:club" do
    $path = "/leave/#{params[:club]}"
    protected!
    if Club.all.exists?(:name => params[:club])
        club = Club.find_by(name: params[:club])
        club.members.delete(session[:username])
        club.save
        club.head.each do |email|
            head = User.find_by(email: email)
            head.notifications.push({:type => "sign-out", :title => "Member Left", :description => "#{session[:username]} left #{club.name}", :id => head.notification_id})
            head.notification_id += 1
            head.save
        end
        club.board.each do |email|
            board = User.find_by(email: email)
            board.notifications.push({:type => "sign-out", :title => "Member Left", :description => "#{session[:username]} left #{club.name}", :id => board.notification_id})
            board.notification_id += 1
            board.save
        end
        redirect "/dashboard/home"
    else
        redirect "/404"
    end
end

get "/delete/:club" do
    $path = "/delete/#{params[:club]}"
    protected!
    user = User.find_by(email: session[:username]).email
    if Club.all.exists?(:name => params[:club])
        club = Club.find_by(name: params[:club])
        if club.head.include? user
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
        if @club.head.include? user
            partial :dashboard_edit, :layout => false
        else
            redirect "/404"
        end
    else
        redirect "/404"
    end
end