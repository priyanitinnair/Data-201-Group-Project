# Data-201-Group-Project
About Dataset
Description

This dataset provides a comprehensive simulation of Starbucks customer ordering patterns across 100,000 transactions, bridging the gap between digital and physical retail channels over a two-year period (2024–2025). It tracks granular metrics including ordering channel (Mobile App, Drive-Thru, In-Store, Kiosk), customer demographics, fulfillment efficiency, and complex basket details like item count and customizations. Specifically engineered to reflect modern retail trends, the data captures the "Digital Venti Effect"—where mobile app users demonstrate higher average order values, more frequent customizations, and distinct age-based adoption skews compared to traditional in-store shoppers.

Primary Use Cases

Channel Migration Analysis: Quantify the shift from physical to digital ordering and identify which customer segments (by age or location) are lagging in mobile adoption.
Customer Segmentation (Persona Building): Use K-Means clustering or RFM (Recency, Frequency, Monetary) analysis to identify high-value "Coffee Enthusiasts" vs. "Morning Commuters."
Predictive Revenue Modeling: Build regression models to predict total_spend based on time of day, store location type, and customization counts.
Operations & Bottleneck Identification: Analyze fulfillment_time_min to find operational inefficiencies between Drive-Thru and Mobile Order-Ahead during peak morning rushes.
Loyalty Program Impact Study: Evaluate how "Rewards Member" status correlates with basket size, visit frequency, and overall customer satisfaction.
Menu Optimization: Correlate specific drink_categories with customization trends to suggest where "Mobile-Only" menu features might drive the most revenue.

Project Structure

sql-project/
│
├── README.md                          
│
├── data/                            
│   ├── raw/
│   │   ├── starbucks_dump.csv         
│   │   └── source_link.txt            
│   │
│   └── processed/                    
│       ├── customer.csv
│       ├── store.csv
│       ├── orders.csv
│       ├── cart_details.csv
│       ├── channel_lookup.csv
│       ├── drink_lookup.csv
│       └── starbucks_customer_ordering_patterns.csv
│
├── schema/                          
│   ├── create_tables.sql              
│   ├── customer.sql                  
│   ├── store.sql
│   ├── orders.sql
│   ├── cart_details.sql
│   ├── channel.sql
│   └── drink_category_lookup.sql
│
├── analysis/                          
│   ├── age_ranges.sql
│   ├── drink_popularity.sql
│   ├── highest_spending_age_group.sql
│   └── popularity_by_region.sql
│
├── diagrams/                          
│   ├── ER_diagram_Chens_Notation.drawio
│   └── EER_diagram.jpeg               
│
├── queries/                          
│   ├── Database_Midterm_Project.pdf
│   ├── Advanced_Query_Sanjana.pdf   
│   └── Final_Queries_Varuna.docx
│
└── presentation/                   
    └── Welcome_to_Starbucks.pptx 
