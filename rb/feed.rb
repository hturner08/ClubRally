def startup
    user = User.find_by(email: session[:username])
    time = Time.new
    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    Club.all.each do |club|
        if club.members.include? session[:username] or club.head.include? session[:username]
            user.notifications.delete_if { |h| h[:title] == club.name}
            clubday = days.index(club.meetingday)
            if (clubday > time.wday and clubday - 2 < time.wday) or (clubday <= 1 and (time.wday > 5 or time.wday == 0))
                #If club is coming up, then push
                user.notifications.push({:type => "clock-o", :title => club.name, :description => "#{club.meetingtime}, #{club.location}", :id => user.notification_id})
                puts "Notifications: #{user.notifications}"
                user.notification_id += 1
                user.save
            end
        end
    end
end

get "/delete/notification/:identifier" do
    user = User.find_by(email: session[:username])
    user.notifications.delete_if { |h| h[:id] == params[:identifier] }
    user.save
    redirect "/dashboard/notifications"
end

get "/dashboard/notifications" do
    $path = "/dashboard/notifications"
    protected!
    startup
    @user = User.find_by(email: session[:username])
    partial :dashboard_notifications, :layout => false
end