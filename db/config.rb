configure :production, :development do
  db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/patch')
  pool = ENV["DB_POOL"] || ENV['MAX_THREADS'] || 1000
  ActiveRecord::Base.establish_connection(
        adapter:  db.scheme == 'postgres' ? 'postgresql' : db.scheme,
        host:      db.host,
        username:  db.user,
        password:  db.password,
        database:  db.path[1..-1],
        encoding:  'utf8',
        pool:      pool
  )
end

