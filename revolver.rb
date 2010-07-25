=begin

Copyright (C) 2010 Lars Olsson (lasso@lassoweb.se)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=end

module Lassoweb

  module Collections

    # This class represents a circular double linked list.
    class Revolver

      Element = Struct.new(:next, :prev, :value) # :nodoc:

      include Enumerable

      # Creates a new circular list. If an array of initial elements are provided
      # they are added to the initial list.
      def initialize(initial_objs = [])
        @endpoint = Element.new
        @endpoint.next = @endpoint
        @endpoint.prev = @endpoint
        @endpoint.value = 0
        @current = @endpoint
        initial_objs.each do |obj|
          self.add obj
        end
      end

      # Adds a new element between the currently selected element and the next element.
      # After this operation the currently selected element points to the newly inserted element.
      def add(obj)
        element = Element.new
        element.next = @current.next
        element.prev = @current
        element.value = obj
        @current.next = element
        @endpoint.prev = element if element.next == @endpoint
        @endpoint.value += 1
        @current = element
      end

      # Removes all elements from the list
      def clear()
        self.first
        until self.empty? do
          self.remove
        end
      end

      # Returns the value of the currently selected element. If the list is empty,
      # nil is returned.
      def current()
        unless self.empty?
          @current.value
        else
          nil
        end
      end

      # Sets the value of the currently selected element. If the list contains no elements,
      # an error is raised.
      def current=(obj)
        unless self.empty?
          @current.value = obj
        else
          raise Exception.new "The list contains no elements."
        end
      end

      # Yields the elements of the list. After this operation
      # The currently selected element remains unaffected.
      def each() # :yields: obj
        unless self.empty?
          tmp = @endpoint.next
          until tmp == @endpoint do
            yield tmp.value
            tmp = tmp.next
          end
        end
      end

      # Returns true if the list contains no elements and false if the list contains at least one element.
      def empty?()
        @endpoint.value == 0
      end

      # Sets the currently selected element to the first element in the list.
      def first()
        @current = @endpoint.next
      end

      # Returns whether the currently selected element is the first element in the list.
      def first?()
        @current == @endpoint.next
      end

      # Returns a string representation of the elements in the list
      def inspect()
        self.to_s()
      end

      # Sets the currently selected element to the last element in the list.
      def last()
        @current = @endpoint.prev
      end

      # Returns whether the currently selected element is the last element in the list.
      def last?()
        @current == @endpoint.prev
      end

      # Applies the supplied block to every element in the list. After this operation
      # the currently selected element remains unaffected
      def map!() # :yields: obj
        unless @endpoint.value == 0
          tmp = @endpoint.next
          until tmp == @endpoint do
            tmp.value = yield tmp.value
            tmp = tmp.next
          end
        end
      end

      # Set the currently selected element to the next element in the list.
      # If the currently selected element is the last in the list, the currently
      # selected element is set to the first element of the list.
      def next()
        @current = @current.next
        @current = @current.next if @current == @endpoint
      end

      # Set the currently selected element to the previous element in the list.
      # If the currently selected element is the first in the list, the currently
      # selected element is set to the last element of the list.
      def prev()
        @current = @current.prev
        @current = @current.prev if @current == @endpoint
      end

      # Removes the currently selected element from the list. After this operation,
      # the currently selected element will point to the next element in the list.
      def remove()
        unless self.empty?
          tmp = @current.next
          @current.prev.next = @current.next
          @current.next.prev = @current.prev
          @current.next = nil
          @current.prev = nil
          @current.value = nil
          @current = nil
          @current = tmp
          @endpoint.value -= 1
        end
      end

      # Returns the number of elements in the list.
      def size()
        @endpoint.value
      end

      # Returns a string representation of the elements in the list
      def to_s()
        unless @endpoint.value == 0
          res = '('
          tmp = @endpoint.next
          until tmp == @endpoint do
            res << tmp.value.to_s
            tmp = tmp.next
            res << ', ' unless tmp == @endpoint
          end
          res << ')'
        else
          res = '()'
        end
        res
      end

      # Returns a string representation of the elements in the list
      def to_str()
        self.to_s()
      end

    end

  end

end
