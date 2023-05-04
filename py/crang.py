import pandas as pd
import boto3


session = boto3.Session(
    aws_access_key_id='araba',
    aws_secret_access_key='araba',
    region_name='eu-central-1'
)

s3 = session.client('s3')



# Read the CSV files
df1 = pd.read_csv('customer.csv')
df2 = pd.read_csv('orders.csv')
df3 = pd.read_csv('items.csv')

# Merge the dataframes
merged_df = pd.merge(df1, df2, on='customer_reference', how='outer')
merged_df = pd.merge(merged_df, df3, on='order_reference', how='outer')


#print(merged_df)
# find the order reference with null cells 
#order_error = merged_df.loc[merged_df['customer_reference'].isnull(), 'order_reference'].values[0]
#print(order_error)


nan_rows = merged_df[merged_df.isna().any(axis=1)]

if not nan_rows.empty:
    # get the data for the error table
    error_table_data = nan_rows.to_json(orient='records')

with open('error.json', 'w') as f:
    f.write(error_table_data)

# Set up the S3 client


s3.upload_file('error.json', 'adducere-partner-bucket', 'errors3.json')

## remove the rows with empty cells
##merged_df = merged_df.dropna()
#