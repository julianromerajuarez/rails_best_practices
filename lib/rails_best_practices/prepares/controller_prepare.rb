# encoding: utf-8
require 'rails_best_practices/core/check'

module RailsBestPractices
  module Prepares
    # Remember controllers and controller methods
    class ControllerPrepare < Core::Check
      DEFAULT_ACTIONS = %w(index show new create edit update destroy)

      def interesting_nodes
        [:module, :class, :def, :command, :var_ref]
      end

      def interesting_files
        CONTROLLER_FILES
      end

      def initialize
        @modules = []
        @methods = Prepares.controller_methods
        @inherited_resources = false
      end

      def start_module(node)
        @modules << node.module_name
      end

      def end_module(node)
        @modules.pop
      end

      # check class node to remember the class name.
      # also check if the controller is inherit from InheritedResources::Base.
      def start_class(node)
        @class_name = class_name(node)
        if "InheritedResources::Base" == node.base_class.to_s
          @inherited_resources = true
          @actions = DEFAULT_ACTIONS
        end
      end

      def class_name(node)
        class_name = node.class_name.to_s
        if @modules.empty?
          class_name
        else
          @modules.map { |modu| "#{modu}::" }.join("") + class_name
        end
      end

      # remember the action names at the end of class node if the controller is a InheritedResources.
      def end_class(node)
        if @inherited_resources
          @actions.each do |action|
            @methods.add_method(@class_name, action)
          end
        end
      end

      # check if there is a DSL call inherit_resources.
      def start_var_ref(node)
        if "inherit_resources" == node.to_s
          @inherited_resources = true
          @actions = DEFAULT_ACTIONS
        end
      end

      # restrict actions for inherited_resources
      def start_command(node)
        if @inherited_resources && "actions" ==  node.message.to_s
          @actions = node.arguments.all.map(&:to_s)
        end
      end

      # check def node to remember all methods.
      #
      # the remembered methods (@methods) are like
      #     {
      #       "Post" => ["create", "destroy"],
      #       "Comment" => ["create"]
      #     }
      def start_def(node)
        method_name = node.method_name.to_s
        @methods.add_method(@class_name, method_name)
      end
    end
  end
end