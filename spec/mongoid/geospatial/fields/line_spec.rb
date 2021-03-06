require 'spec_helper'

describe Mongoid::Geospatial::Line do
  describe '(de)mongoize' do
    it 'should support a field mapped as linestring' do
      river = River.new(course: [[5, 5], [6, 5], [6, 6], [5, 6]])
      expect(river.course).to be_a Mongoid::Geospatial::Line
      expect(river.course).to eq([[5, 5], [6, 5], [6, 6], [5, 6]])
    end

    it 'should support a field mapped as linestring' do
      River.create!(course: [[5, 5], [6, 5], [6, 6], [5, 6]])
      expect(River.first.course).to eq([[5, 5], [6, 5], [6, 6], [5, 6]])
    end

    it 'should have a bounding box' do
      geom = Mongoid::Geospatial::Line.new [[1, 5], [6, 5], [6, 6], [5, 6]]
      expect(geom.bbox).to eq([[1, 5], [6, 6]])
    end

    it 'should have a center point' do
      geom = Mongoid::Geospatial::Line.new [[1, 1], [1, 1], [9, 9], [9, 9]]
      expect(geom.center).to eq([5.0, 5.0])
    end

    it 'should have a radius helper' do
      geom = Mongoid::Geospatial::Line.new [[1, 1], [1, 1], [9, 9], [9, 9]]
      expect(geom.radius(10)).to eq([[5.0, 5.0], 10])
    end

    it 'should have a radius sphere' do
      geom = Mongoid::Geospatial::Line.new [[1, 1], [1, 1], [9, 9], [9, 9]]
      expect(geom.radius_sphere(10)[1]).to be_within(0.001).of(0.001569)
    end
  end
end
