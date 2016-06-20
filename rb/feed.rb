def startup
    @user = User.find_by(email: session[:username])
    time = Time.new
    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    @user.clubs.each do |name|
        club = Club.find_by(:name => name)
        clubday = days.index(club.meetingtime.split(',')[0])
        if (clubday > time.wday and clubday - 2 < time.wday) or (clubday <= 1 and (time.wday > 5 or time.wday == 0)) and !club.nomeeting and approved?(club) and !@user.notifications.any? { |h| h[:title] == name }
            send_notification(@user, "clock-o", club.name, "#{club.meetingtime}, #{club.location}")
        end
    end
end

def send_notification(user, type, title, description)
    user.notifications.push({:type => type, :title => title, :description => description, :id => user.notification_id})
    user.notification_id += 1
    user.save
end

get "/delete/notification/:id" do
    user = User.find_by(email: session[:username])
    user.notifications.delete_if { |h| h[:id] == params[:id].to_i }
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
