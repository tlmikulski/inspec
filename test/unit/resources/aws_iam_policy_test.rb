require 'helper'

# MAIPSB = MockAwsIamPolicySingularBackend
# Abbreviation not used outside this file

#=============================================================================#
#                            Constructor Tests
#=============================================================================#
class AwsIamPolicyConstructorTest < Minitest::Test

  def setup
    AwsIamPolicy::BackendFactory.select(MAIPSB::Empty)
  end

  def test_rejects_empty_params
    assert_raises(ArgumentError) { AwsIamPolicy.new }
  end

  def test_accepts_policy_name_as_scalar
    AwsIamPolicy.new('test-policy-1')
  end

  def test_accepts_policy_name_as_hash
    AwsIamPolicy.new(policy_name: 'test-policy-1')
  end

  def test_rejects_unrecognized_params
    assert_raises(ArgumentError) { AwsIamPolicy.new(shoe_size: 9) }
  end
end


#=============================================================================#
#                               Search / Recall
#=============================================================================#
class AwsIamPolicyRecallTest < Minitest::Test

  def setup
    AwsIamPolicy::BackendFactory.select(MAIPSB::Basic)
  end

  def test_search_hit_via_scalar_works
    assert AwsIamPolicy.new('test-policy-1').exists?
  end

  def test_search_hit_via_hash_works
    assert AwsIamPolicy.new(policy_name: 'test-policy-1').exists?
  end

  def test_search_miss_is_not_an_exception
    refute AwsIamPolicy.new(policy_name: 'non-existant').exists?
  end
end

#=============================================================================#
#                               Properties
#=============================================================================#
class AwsIamPolicyPropertiesTest < Minitest::Test

  def setup
    AwsIamPolicy::BackendFactory.select(MAIPSB::Basic)
  end

  def test_property_arn
    assert_equal('arn:aws:iam::aws:policy/test-policy-1', AwsIamPolicy.new('test-policy-1').arn)
    assert_nil(AwsIamPolicy.new(policy_name: 'non-existant').arn)
  end

  def test_property_default_version_id
    assert_equal('v1', AwsIamPolicy.new('test-policy-1').default_version_id)
    assert_nil(AwsIamPolicy.new(policy_name: 'non-existant').default_version_id)
  end

  def test_property_attachment_count
    assert_equal(3, AwsIamPolicy.new('test-policy-1').attachment_count)
    assert_nil(AwsIamPolicy.new(policy_name: 'non-existant').attachment_count)
  end

  def test_property_attached_users
    assert_equal(['test-user'], AwsIamPolicy.new('test-policy-1').attached_users)
    assert_nil(AwsIamPolicy.new(policy_name: 'non-existant').attached_users)
  end

  def test_property_attached_groups
    assert_equal(['test-group'], AwsIamPolicy.new('test-policy-1').attached_groups)
    assert_nil(AwsIamPolicy.new(policy_name: 'non-existant').attached_groups)
  end

  def test_property_attached_roles
    assert_equal(['test-role'], AwsIamPolicy.new('test-policy-1').attached_roles)
    assert_nil(AwsIamPolicy.new(policy_name: 'non-existant').attached_roles)
  end

  def test_property_policy
    policy = AwsIamPolicy.new('test-policy-1').policy
    assert_kind_of(Hash, policy)
    assert(policy.key?('Statement'), "test-policy-1 should have a Statement key when unpacked")
    assert_equal(1, policy['Statement'].count, "test-policy-1 should have 1 statements when unpacked")
    assert_nil(AwsIamPolicy.new('non-existant').policy)    
  end

  def test_property_statement_count
    assert_nil(AwsIamPolicy.new('non-existant').statement_count)
    assert_equal(1, AwsIamPolicy.new('test-policy-1').statement_count)
    assert_equal(2, AwsIamPolicy.new('test-policy-2').statement_count)
  end
end


#=============================================================================#
#                               Matchers
#=============================================================================#
class AwsIamPolicyMatchersTest < Minitest::Test

  def setup
    AwsIamPolicy::BackendFactory.select(MAIPSB::Basic)
  end

  def test_matcher_attached_positive
    assert AwsIamPolicy.new('test-policy-1').attached?
  end

  def test_matcher_attached_negative
    refute AwsIamPolicy.new('test-policy-2').attached?
  end
  
  def test_matcher_attached_to_user_positive
    assert AwsIamPolicy.new('test-policy-1').attached_to_user?('test-user')
  end

  def test_matcher_attached_to_user_negative
    refute AwsIamPolicy.new('test-policy-2').attached_to_user?('test-user')
  end
  
  def test_matcher_attached_to_group_positive
    assert AwsIamPolicy.new('test-policy-1').attached_to_group?('test-group')
  end

  def test_matcher_attached_to_group_negative
    refute AwsIamPolicy.new('test-policy-2').attached_to_group?('test-group')
  end

  def test_matcher_attached_to_role_positive
    assert AwsIamPolicy.new('test-policy-1').attached_to_role?('test-role')
  end

  def test_matcher_attached_to_role_negative
    refute AwsIamPolicy.new('test-policy-2').attached_to_role?('test-role')
  end
end

#=============================================================================#
#                               Test Fixtures
#=============================================================================#
module MAIPSB
  class Empty < AwsBackendBase
    def list_policies(query)
      OpenStruct.new(policies: [])
    end
  end

  class Basic < AwsBackendBase
    def list_policies(query)
      fixtures = [
        OpenStruct.new({
          policy_name: 'test-policy-1',
          arn: 'arn:aws:iam::aws:policy/test-policy-1',
          default_version_id: 'v1',
          attachment_count: 3,
          is_attachable: true,
        }),
        OpenStruct.new({
          policy_name: 'test-policy-2',
          arn: 'arn:aws:iam::aws:policy/test-policy-2',
          default_version_id: 'v1',
          attachment_count: 0,
          is_attachable: false,
        }),
      ]
      OpenStruct.new({ policies: fixtures })
    end

    def list_entities_for_policy(query)
      policy = {}
      policy['arn:aws:iam::aws:policy/test-policy-1'] =
      {
        policy_groups: [
          OpenStruct.new({
            group_name: 'test-group',
            group_id: 'AIDAIJ3FUBXLZ4VXV34LE',
          }),
        ],
        policy_users: [
          OpenStruct.new({
            user_name: 'test-user',
            user_id: 'AIDAIJ3FUBXLZ4VXV34LE',
          }),
        ],
        policy_roles: [
          OpenStruct.new({
            role_name: 'test-role',
            role_id: 'AIDAIJ3FUBXLZ4VXV34LE',
          }),
        ],
      }
      policy['arn:aws:iam::aws:policy/test-policy-2'] =
      {
        policy_groups: [],
        policy_users: [],
        policy_roles: [],
      }
      OpenStruct.new( policy[query[:policy_arn]] )
    end

    def get_policy_version(query)
      fixtures = {
        'arn:aws:iam::aws:policy/test-policy-1' => {
          'v1' => OpenStruct.new(
            # This is the integration test fixture "beta"
            document: '%7B%0A%20%20%22Version%22%3A%20%222012-10-17%22%2C%0A%20%20%22Statement%22%3A%20%5B%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%22Sid%22%3A%20%22beta01%22%2C%0A%20%20%20%20%20%20%22Action%22%3A%20%5B%0A%20%20%20%20%20%20%20%20%22ec2%3ADescribeSubnets%22%2C%0A%20%20%20%20%20%20%20%20%22ec2%3ADescribeSecurityGroups%22%0A%20%20%20%20%20%20%5D%2C%0A%20%20%20%20%20%20%22Effect%22%3A%20%22Deny%22%2C%0A%20%20%20%20%20%20%22Resource%22%3A%20%5B%0A%20%20%20%20%20%20%20%20%22arn%3Aaws%3Aec2%3A%3A%3A%2A%22%2C%0A%20%20%20%20%20%20%20%20%22%2A%22%0A%20%20%20%20%20%20%5D%0A%20%20%20%20%7D%0A%20%20%5D%0A%7D%0A'
          )
        },
        'arn:aws:iam::aws:policy/test-policy-2' => {
          'v1' => OpenStruct.new(
            # This is AWS-managed CloudWatchEventsFullAccess
            document: '%7B%0A%20%20%20%20%22Version%22%3A%20%222012-10-17%22%2C%0A%20%20%20%20%22Statement%22%3A%20%5B%0A%20%20%20%20%20%20%20%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%22Sid%22%3A%20%22CloudWatchEventsFullAccess%22%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20%22Effect%22%3A%20%22Allow%22%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20%22Action%22%3A%20%22events%3A%2A%22%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20%22Resource%22%3A%20%22%2A%22%0A%20%20%20%20%20%20%20%20%7D%2C%0A%20%20%20%20%20%20%20%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%22Sid%22%3A%20%22IAMPassRoleForCloudWatchEvents%22%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20%22Effect%22%3A%20%22Allow%22%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20%22Action%22%3A%20%22iam%3APassRole%22%2C%0A%20%20%20%20%20%20%20%20%20%20%20%20%22Resource%22%3A%20%22arn%3Aaws%3Aiam%3A%3A%2A%3Arole%2FAWS_Events_Invoke_Targets%22%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%5D%0A%7D'
          )
        }
      }
      pv = fixtures.dig(query[:policy_arn], query[:version_id])
      return pv if pv
      raise Aws::IAM::Errors::NoSuchEntity.new(nil, nil)
    end
  end
end