require 'mongoid'
require 'active_support/core_ext/string/inflections'
require 'active_support/concern'
require 'mongoid/geospatial/helpers/spatial'
require 'mongoid/geospatial/helpers/sphere'
require 'mongoid/geospatial/helpers/delegate'

require 'mongoid/geospatial/fields/geometry_field'

%w(point circle box line polygon).each do |type|
  require "mongoid/geospatial/fields/#{type}"
end

module Mongoid
  #
  # Main Geospatial module
  #
  # include Mongoid::Geospatial
  #
  module Geospatial
    extend ActiveSupport::Concern

    LNG_SYMBOLS = [:x, :lon, :long, :lng, :longitude,
                   'x', 'lon', 'long', 'lng', 'longitude']
    LAT_SYMBOLS = [:y, :lat, :latitude, 'y', 'lat', 'latitude']

    EARTH_RADIUS_KM = 6371 # taken directly from mongodb
    RAD_PER_DEG = Math::PI / 180

    EARTH_RADIUS = {
      km: EARTH_RADIUS_KM,
      m: EARTH_RADIUS_KM * 1000,
      mi: EARTH_RADIUS_KM * 0.621371192, # taken directly from mongodb
      ft: EARTH_RADIUS_KM * 5280 * 0.621371192,
      sm: EARTH_RADIUS_KM * 0.53995680345572 # sea mile
    }

    mattr_accessor :lng_symbols
    mattr_accessor :lat_symbols
    mattr_accessor :earth_radius
    mattr_accessor :factory

    @@lng_symbols  = LNG_SYMBOLS.dup
    @@lat_symbols  = LAT_SYMBOLS.dup
    @@earth_radius = EARTH_RADIUS.dup

    included do
      # attr_accessor :geo
      cattr_accessor :spatial_fields, :spatial_fields_indexed
      self.spatial_fields = []
      self.spatial_fields_indexed = []
    end

    def self.with_rgeo!
      require 'mongoid/geospatial/wrappers/rgeo'
    end

    def self.with_georuby!
      require 'mongoid/geospatial/wrappers/georuby'
    end

    module ClassMethods #:nodoc:
      def geo_field(name, options = {})
        field name, { type: Mongoid::Geospatial::Point,
                      spatial: true }.merge(options)
      end

      # create spatial index for given field
      # @param [String,Symbol] name
      # @param [Hash] options options for spatial_index
      # http://www.mongodb.org/display/DOCS/Geospatial+Indexing#GeospatialIndexing-geoNearCommand
      def spatial_index(name, options = {})
        spatial_fields_indexed << name
        index({ name => '2d' }, options)
      end

      def sphere_index(name, options = {})
        spatial_fields_indexed << name
        index({ name => '2dsphere' }, options)
      end

      def spatial_scope(field, _opts = {})
        singleton_class.class_eval do
          # define_method(:close) do |args|
          define_method(:nearby) do |args|
            queryable.where(field.near_sphere => args)
          end
        end
      end
    end
  end
end

# model.instance_eval do # wont work
# #   define_method "near_#{field.name}" do |*args|
# #     self.where(field.name => args)
# #   end
# end

# define_method "near_#{field.name}" do |*args|
#   queryable.where(field.near_sphere => args)
# end

# model.class_eval do
#   define_method "close_to" do |*args|
#     queriable.where(field.name.near_sphere => *args)
#   end
# end
