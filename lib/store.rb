require 'ostruct'

module Sellbot
  class Store
    class InvalidConfiguration < StandardError; end
    class NotFound < StandardError; end

    LOAD_PATH = 'config/store.yml'

    class << self
      def setup!
        self.reload!
      end

      def reload!
        Config.log "Loading store configuration from #{LOAD_PATH}..."
        begin
          store_file = File.join( Config.path, LOAD_PATH )
          store = YAML::load_file( store_file ).recursively_symbolize_keys
        rescue
          store = {}
          raise "#{self.name} has no 'products' or 'packages'!"
        end

        # jigger products, there must be at least one
        # also add key kind: :product to all products
        begin
          store[:products].entries.each do |id, info|
            store[:products][id].merge! id: id, kind: :product
          end
        rescue
          raise InvalidConfiguration.new(
            "Store configuration must include at least one product."
          )
        end

        # jigger packages, not required
        # also add key kind: :package to all packages
        (store[:packages]||{}).entries.each do |id, info|
          store[:packages][id].merge! id: id, kind: :package

          # ensure this package's products exist
          #   contents == '*' means 'all products'
          if store[:packages][id][:contents] == '*'
            store[:packages][id][:contents] = store[:products].values
          else
            #   otherwise, raise if we dont find a product
            store[:packages][id][:contents].map! do |pid|
              pid = pid.to_sym
              if store[:products].has_key?( pid )
                next store[:products][pid]
              else
                raise InvalidConfiguration.new(
                  "Packages ':contents' field must list only existing products or '*'"
                )
              end
            end
          end
        end

        @@store = ::OpenStruct.new( store )
      end

      def ensure_newest!(db)
        self.reload! unless self.version == db.store_version
      end

      def version
        Digest::SHA1.hexdigest( @@store.inspect )
      end

      def packages
        @@store.packages.values
      end
      def products
        @@store.products.values
      end

      def find_purchaseable( item_id )
        # it's a package?
        packages.find do |info|
          if info[:id] == item_id.to_sym
            return info.dup.merge kind: :package
          end
        end

        # or a product?
        products.find do |info|
          if info[:id] == item_id.to_sym
            return info.dup.merge kind: :product
          end
        end

        raise NotFound.new(
          "Could not find purchaseable package or product with id: #{item_id}"
        )
      end

      def find_items( item_id )
        raise NotFound.new( "Cannot find items without an id" ) unless item_id
        # it's a package?
        packages.find do |info|
          if info[:id] == item_id.to_sym
            return info[:contents]
          end
        end

        # or a product?
        products.find do |info|
          if info[:id] == item_id.to_sym
            return [info.dup]
          end
        end

        raise NotFound.new(
          "Could not find #{kind} for id: #{item_id}"
        )
      end
    end
  end
end
