#
# AssetBucket
#
class AssetBucket < BucketHelper

  def initialize
    super CDO.assets_s3_bucket, CDO.assets_s3_directory
  end

  def allowed_file_types
    # Only allow specific image and sound types to be uploaded by users.
    %w(.jpg .jpeg .gif .png .mp3)
  end

end
