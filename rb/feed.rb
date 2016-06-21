def comingup?(club)
    time = Time.new.to_i
    clubdate = Chronic.parse("next #{club.meetingtime.split(',')[0]} #{club.meetingtime.split(' ')[1]}").to_i

    if ((clubdate - time) / 3600) < 48
        return true
    else
        return false
    end
end

def startup
    @user = User.find_by(email: session[:username])
    @user.clubs.each do |name|
        club = Club.find_by(:name => name)
        if comingup?(club) and !club.nomeeting and approved?(club) and !@user.notifications.any? { |h| h[:title] == name }
            send_notification(@user, "clock-o", club.name, "#{club.meetingtime}, #{club.location}")
        elsif !comingup?(club) and @user.notifications.any? { |h| h[:title] == name }
            @user.notifications.delete_if { |h| h[:title] == club.name}
            @user.save
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
