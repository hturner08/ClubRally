get "/dashboard/createclub" do
    $path = "/dashboard/createclub"
    protected!
    partial :dashboard_createclub, :layout => false
end

post "/createclub" do
    Club.create(:name => params[:name], :description => params[:description], :img => params[:img], :head => [session[:username]], :board => [], :members => [], :meetingtime => params[:time], :meetingday => params[:weekday], :location => params[:location])
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
    if Club.all.exists?(:name => params[:club])
        @club = Club.find_by(name: params[:club])
        people = "&cc="
        @club.members.each do |member|
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
            head.notifications.push({:type => "user", :title => "New Member", :description => "#{session[:username]} joined #{club.name}"})
            head.save
        end
        club.board.each do |email|
            board = User.find_by(email: email)
            board.notifications.push({:type => "user", :title => "New Member", :description => "#{session[:username]} joined #{club.name}"})
            board.save
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
            head.notifications.push({:type => "times", :title => "Member Left", :description => "#{session[:username]} left #{club.name}"})
            head.save
        end
        club.board.each do |email|
            board = User.find_by(email: email)
            board.notifications.push({:type => "times", :title => "Member Left", :description => "#{session[:username]} left #{club.name}"})
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