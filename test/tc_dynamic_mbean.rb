# Copyright 2008 Jeff Mesnil (http://jmesnil.net)

require "test/unit"
require "jmx4r"


class TestDynamicMBean < Test::Unit::TestCase

  import java.lang.management.ManagementFactory
  import javax.management.ObjectName

  class AttributeTypesMBean < JMX::DynamicMBean
    rw_attribute :string_attr, :string, "a String attribute"
    rw_attribute :byte_attr, :byte, "a Byte attribute"
    rw_attribute :int_attr, :int, "a Integer attribute"
    rw_attribute :long_attr, :long, "a Long attribute"
    rw_attribute :float_attr, :float, "a Float attribute"
    rw_attribute :double_attr, :double, "a Double attribute"
    rw_attribute :list_attr, :list, "a List attribute"
    rw_attribute :map_attr, :map, "a Map attribute"
    rw_attribute :set_attr, :set, "a Set attribute"
    rw_attribute :boolean_attr, :boolean, "a Boolean attribute"
  end

  def test_attribute_types
    mbean = AttributeTypesMBean.new
    mbeanServer = ManagementFactory.platform_mbean_server
    mbeanServer.register_mbean mbean, ObjectName.new("jmx4r:name=AttributeTypesMBean")

    mbean = JMX::MBean.find_by_name "jmx4r:name=AttributeTypesMBean", :connection => mbeanServer
    mbean.string_attr = "test"
    assert_equal("test", mbean.string_attr)

    mbean.byte_attr = 9
    assert_equal(9, mbean.byte_attr)

    mbean.int_attr = 23
    assert_equal(23, mbean.int_attr)

    mbean.long_attr = 33
    assert_equal(33, mbean.long_attr)

    mbean.float_attr = 91.0
    assert_equal(91.0, mbean.float_attr)

    mbean.float_attr = 7.0
    assert_equal(7.0, mbean.float_attr)

    mbean.list_attr = [1, 2, 3]
    assert_equal([1, 2, 3], mbean.list_attr.to_a)

    mbean.set_attr = [1, 2, 3]
    assert_equal([1, 2, 3].sort, mbean.list_attr.to_a.sort)

    mbean.map_attr = { "a" => 1, "b" => 2}
    assert_equal({ "a" => 1, "b" => 2}.to_a.sort, mbean.map_attr.to_a.sort)

    mbean.boolean_attr = true
    assert_equal(true, mbean.boolean_attr)
  end

  class OperationInvocationMBean < JMX::DynamicMBean
    operation "reverse the string passed in parameter"
    parameter :string, "arg", "a String to reverse"
    returns :string
    def reverse(arg)
      arg.reverse
    end
  end

  def test_operation_invocation
    mbean = OperationInvocationMBean.new
    mbeanServer = ManagementFactory.platform_mbean_server
    mbeanServer.register_mbean mbean, ObjectName.new("jmx4r:name=OperationInvocationMBean")

    mbean = JMX::MBean.find_by_name "jmx4r:name=OperationInvocationMBean", :connection => mbeanServer
    assert_equal("oof", mbean.reverse("foo"))
  end

  class Foo < JMX::DynamicMBean
    rw_attribute :foo_attr, :string

    operation
    parameter :string
    returns :string
    def foo(arg)
       "foo #{arg}"
    end
  end

  class Bar < JMX::DynamicMBean
    rw_attribute :bar_attr, :string

    operation
    parameter :string
    returns :string
    def bar(arg)
       "bar #{arg}"
    end
  end

  def test_separate_dynamic_beans_have_separate_operations_and_attributes
     mbean_server = ManagementFactory.platform_mbean_server
     mbean_server.register_mbean Foo.new, ObjectName.new("jmx4r:name=foo")
     mbean_server.register_mbean Bar.new, ObjectName.new("jmx4r:name=bar")

     foo_mbean = JMX::MBean.find_by_name "jmx4r:name=foo", :connection => mbean_server
     assert_equal "foo test", foo_mbean.foo("test")
     assert_raise(NoMethodError){
        foo_mbean.bar("test")
     }
     foo_mbean.foo_attr = "test"
     assert_equal "test", foo_mbean.foo_attr
     assert_raise(NoMethodError){
        foo_mbean.bar_attr = "test"
     }
     bar_mbean = JMX::MBean.find_by_name "jmx4r:name=bar", :connection => mbean_server
     assert_equal "bar test", bar_mbean.bar("test")
     assert_raise(NoMethodError) {
        bar_mbean.foo("test")
     }
     bar_mbean.bar_attr = "test"
     assert_equal "test", bar_mbean.bar_attr
     assert_raise(NoMethodError){
        bar_mbean.foo_attr = "test"
     }
  end
end
