require 'sinatra'
require 'haml'
require 'sinatra/partial'
require 'active_record'
require 'bcrypt'
require 'rest_client'
require 'securerandom'
require './db/config.rb'
require './user.rb'
require './rb/auth.rb'

enable :sessions

def startup
    user = User.find_by(email: session[:username])
    time = Time.new
    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    Club.all.each do |club|
        if club.members.include? session[:username] or club.head.include? session[:username]
            clubday = days.index(club.meetingday)
            if (clubday > time.wday and clubday - 2 < time.wday) or (clubday <= 1 and (time.wday > 5 or time.wday == 0))
                #If club is coming up, then push
                user.notifications.push({:type => "clock-o", :title => club.name, :description => "#{club.meetingtime}, #{club.location}"}, :id => "#{club.name}#{club.meetingtime}")
                puts "Notifications: #{user.notifications}"
                user.save
            end
        end
    end
end

get "/" do 
    if login? 
        startup
        redirect "/dashboard/home"
    else
        $error = nil
        $register_error = nil
        partial :index, :layout => false
    end
end

get "/dashboard/home" do
    $path = "/dashboard/home"
    protected!
    @clubs = []
    Club.all.each do |club|
        if club.members.include? session[:username] or club.head.include? session[:username]
            @clubs << club
        end
    end
    partial :dashboard_home, :layout => false
end

get "/dashboard/browse" do
    $path = "/dashboard/browse"
    protected!
    @clubs = Club.all
    partial :dashboard_browse, :layout => false
end

get "/dashboard/notifications" do
    $path = "/dashboard/notifications"
    protected!
    startup
    @user = User.find_by(email: session[:username])
    partial :dashboard_notifications, :layout => false
end

get "/verify" do
    if login? 
        redirect $path
    end
    
    partial :verify, :layout => false
end

get "/debug/dbinit" do 
    dbinit
    redirect "/"
end

get "/debug/mail" do
    send_simple_message
    redirect "/"
end

get "/debug/random" do
    puts SecureRandom.hex
    redirect "/"
end

not_found do
    status 404
    partial :oops, :layout => false
end

get "/404" do
    partial :oops, :layout => false
end

get "/dashboard/createclub" do
    $path = "/dashboard/createclub"
    protected!
    partial :dashboard_createclub, :layout => false
end

get "/dashboard/search" do
    $path = "/dashboard/search?search=#{params[:search]}" 
    protected!
    query = params[:search].downcase
    @clubs = []
    Club.all.each do |club|
        all_data = "#{club.name} #{club.description}"
        if all_data.downcase.include? query
            @clubs.push(club)
        end
    end
    partial :dashboard_search, :layout => false
end

post "/createclub" do
    Club.create(:name => params[:name], :description => params[:description], :img => params[:img], :head => [session[:username]], :members => [], :meetingtime => params[:time], :meetingday => params[:weekday], :location => params[:location])
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

def dbinit
    ActiveRecord::Migration.class_eval do
        if User.table_exists?
            drop_table :users
        end 
        if Club.table_exists?
            drop_table :clubs
        end 
        create_table :users do |t|
            t.string :email
            t.string :salt
            t.string :passwordhash
            t.boolean :verified
            t.string :verification_code
            t.string :notifications
        end
        create_table :clubs do |t|
            t.string :name
            t.string :description
            t.string :head, array: true
            t.string :board, array: true
            t.string :img
            t.string :members, array: true
            t.string :meetingtime
            t.string :meetingday
            t.string :location
        end
    end
end
