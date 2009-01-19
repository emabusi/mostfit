class Payment
  include DataMapper::Resource
  
  property :id,             Serial
  property :principal,      Integer, :nullable => false
  property :interest,       Integer, :nullable => false
  property :received_on,    Date,    :nullable => false
  property :created_at,     DateTime
  property :deleted_at,     ParanoidDateTime

  belongs_to :loan
  belongs_to :user
  belongs_to :deleted_by, :class_name => 'User'

  validates_present :loan_id, :user_id

  before :destroy do
    if self.deleted_by.nil?
      errors.add("Cannot delete this payment without setting the :deleted_at property, please report this error.")
      throw :halt
    end
  end

end



# # class Payment (models.Model):
# #     """ """
# #     num = models.IntegerField()
# #     date = models.DateField()
# #     principal = models.FloatField()
# #     interest = models.FloatField(blank=True,null=True)
# #     class Meta:
# #         """ """
# #         get_latest_by = "date"