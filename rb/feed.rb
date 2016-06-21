def get_club_time(club)
    if Chronic.parse("today").wday == Chronic.parse("this #{club.meetingtime.split(',')[0]}").wday
        clubdate = Chronic.parse("today #{club.meetingtime.split(' ')[1]}")
    else
        clubdate = Chronic.parse("this #{club.meetingtime.split(',')[0]} #{club.meetingtime.split(' ')[1]}")
    end

    return clubdate
end

def comingup?(club)
    time = Time.new.to_i

    clubdate = get_club_time(club)

    if (((clubdate.to_i - time) / 3600) < 48) and (((clubdate.to_i - time) / 3600) > 0)
        puts "hello"
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
            send_notification(@user, "clock-o", club.name, "#{club.meetingtime}, #{club.location}", get_club_time(club).to_i)
        elsif !comingup?(club) and @user.notifications.any? { |h| h[:title] == name }
            @user.notifications.delete_if { |h| h[:title] == club.name}
            @user.save
        end
    end
    @user.notifications = @user.notifications.sort_by { |h| h[:timestamp] }
    @user.save
end

def send_notification(user, type, title, description, timestamp)
    user.notifications.push({:type => type, :title => title, :description => description, :id => user.notification_id, :timestamp => timestamp})
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
