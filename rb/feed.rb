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
