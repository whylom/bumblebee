module Bumblebee
  class Pager
    attr_reader :scope

    def initialize(scope)
      @scope = scope
    end

    def count
      scope.get.total_pages
    end

    def first
      at(1)
    end

    def last
      at(count)
    end

    def at(page)
      scope.where(page: page).get.records
    end

    alias_method :[], :at

    def each
      return enum_for(:each) unless block_given?
      (1..count).each { |i| yield at(i) }
    end
  end
end
