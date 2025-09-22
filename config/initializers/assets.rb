# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')
Rails.application.config.assets.precompile += %w( axios.js )
Rails.application.config.assets.precompile += %w( bootstrap-checkbox.min.js )
Rails.application.config.assets.precompile += %w( swalert.js )
# Rails.application.config.assets.precompile += %w( redirect.js )
# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
Rails.application.config.assets.precompile += %w( cable.js )
Rails.application.config.assets.precompile += %w( char_google.js )
# Rails.application.config.assets.precompile += %w( choosen.js)
# Rails.application.config.assets.precompile += %w( style.css )
Rails.application.config.assets.precompile += %w( select2.js )
Rails.application.config.assets.precompile += %w( select2.css )
Rails.application.config.assets.precompile += %w( vue.min.js )
Rails.application.config.assets.precompile += %w( datos_vue.js )
Rails.application.config.assets.precompile += %w( bootstrap.min.js )
Rails.application.config.assets.precompile += %w( popper.min.js )
Rails.application.config.assets.precompile += %w( componente.js )
Rails.application.config.assets.precompile += %w( componente_usuarios.js )
Rails.application.config.assets.precompile += %w( componente_chats.js )
Rails.application.config.assets.precompile += %w( datos_vue_chats.js )
Rails.application.config.assets.precompile += %w( componente_tablas.js )