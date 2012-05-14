Padrino.configure_apps do
  set :session_secret, Sellbot::Config.session || ENV['SESSION_SECRET']
end

Padrino.mount("Sellbot::Web").to('/')
