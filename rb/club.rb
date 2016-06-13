def clubincludesuser? (club)
    if club.members.include? session[:username] or club.board.include? session[:username] or club.head.include? session[:username]
        return true
    else
        return false
    end
end

$categories = [{:name => "STEM", :icon => "flask", :img => "stem.jpeg"}, {:name => "Politics and Debate", :icon => "balance-scale", :img => "publicspeaking.jpg"}, {:name => "Art", :icon => "paint-brush", :img => "art.jpeg"}, {:name => "Non Sibi", :icon => "hand-peace-o", :img => "nonsibi.jpg"}, {:name => "Publications", :icon => "file-text", :img => "books.jpeg"}, {:name => "Athletics", :icon => "futbol-o", :img => "athletics.jpeg"}, {:name => "Music", :icon => "music", :img => 
"music.jpeg"}]

get "/dashboard/category/:category" do
    $path = "/dashboard/category/#{params[:category]}"
    protected!
    startup
    #if category exists
    if $categories.any? {|h| h[:name] == params[:category]}
        @category = $categories.find {|h| h[:name] == params[:category] }
        @clubs = Club.where(tag: params[:category])
        puts "category: #{@category}"
        partial :dashboard_categories, :layout => false
    else
        redirect "/404"
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
    @filename = params[:img][:filename]
    file = params[:img][:tempfile]

    File.open("./public/upload/#{@filename}", 'wb') do |f|
        f.write(file.read)
    end
    
    Club.create(:name => params[:name], :description => params[:description], :img => @filename, :head => [session[:username]], :board => [], :members => [], :meetingtime => "#{params[:weekday]}, #{params[:time]}", :location => params[:location], :tag => params[:tags])
    redirect "/dashboard/home"
end

post "/updateimage" do
    @filename = params[:img][:filename]
    file = params[:img][:tempfile]

    File.open("./public/upload/#{@filename}", 'wb') do |f|
        f.write(file.read)
    end
    club = Club.find_by(name: params[:club])
    club.img = @filename
    club.save
    redirect "/dashboard/club/#{params[:club]}"
end

post "/editclub" do
    club = Club.find_by(name: params[:name])
    club.description = params[:description]
    club.meetingtime = "#{params[:weekday]}, #{params[:time]}"
    club.location = params[:location]
    club.tag = params[:tags]
    club.save
    redirect "/dashboard/club/#{params[:name]}"
end

get "/dashboard/club/:club" do
    $path = "/dashboard/club/#{params[:club]}"
    protected!
    startup
    if Club.all.exists?(:name => params[:club])
        @club = Club.find_by(name: params[:club])
        people = ""
        @club.members.each do |member|
            people << "#{member};"
        end
        @club.board.each do |member|
            people << "#{member};" unless member == session[:username]
        end
        @club.head.each do |member|
            people << "#{member};" unless member == session[:username]
        end
        
        people = people[0...-1]
        @list = "mailto:#{people}?subject=#{@club.name}"
        
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