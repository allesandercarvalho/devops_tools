import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum KnowledgeViewMode { grid, list }

class AWSKnowledgeBaseScreen extends StatefulWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const AWSKnowledgeBaseScreen({
    super.key,
    required this.searchQuery,
    required this.viewType,
    required this.selectedCategory,
  });

  @override
  State<AWSKnowledgeBaseScreen> createState() => _AWSKnowledgeBaseScreenState();
}

class _AWSKnowledgeBaseScreenState extends State<AWSKnowledgeBaseScreen> {
  // final TextEditingController _searchController = TextEditingController();
  // String _searchQuery = '';
  // String _selectedCategory = 'All';
  // KnowledgeViewMode _viewMode = KnowledgeViewMode.grid;
  
  // Mock Data
  final List<Map<String, String>> _articles = [
    {
      'title': 'S3 Best Practices',
      'category': 'Storage',
      'description': 'Learn how to optimize S3 for performance and cost.',
      'content': '1. Use S3 Intelligent-Tiering for unknown access patterns.\\n2. Enable Transfer Acceleration for long-distance uploads.\\n3. Use Lifecycle Policies to transition objects to Glacier.',
      'readTime': '5 min',
    },
    {
      'title': 'EC2 Cost Optimization',
      'category': 'Compute',
      'description': 'Strategies to reduce your EC2 bill.',
      'content': '1. Use Spot Instances for fault-tolerant workloads.\\n2. Right-size instances based on CloudWatch metrics.\\n3. Purchase Savings Plans for predictable usage.',
      'readTime': '7 min',
    },
    {
      'title': 'IAM Security Checklist',
      'category': 'Security',
      'description': 'Essential security steps for IAM.',
      'content': '1. Enable MFA for the root account.\\n2. Create individual IAM users.\\n3. Use groups to assign permissions.\\n4. Rotate access keys regularly.',
      'readTime': '4 min',
    },
    {
      'title': 'Lambda Cold Starts',
      'category': 'Serverless',
      'description': 'Understanding and mitigating cold starts.',
      'content': '1. Use Provisioned Concurrency for critical functions.\\n2. Minimize deployment package size.\\n3. Choose lighter runtimes like Go or Node.js.',
      'readTime': '6 min',
    },
    {
      'title': 'RDS Multi-AZ Deployments',
      'category': 'Database',
      'description': 'High availability for your relational databases.',
      'content': '1. Enable Multi-AZ for production workloads.\\n2. Understand the failover process.\\n3. Use Read Replicas for scaling read traffic.',
      'readTime': '8 min',
    },
    {
      'title': 'VPC Networking Fundamentals',
      'category': 'Network',
      'description': 'Understanding AWS Virtual Private Cloud basics.',
      'content': '1. Plan your CIDR blocks carefully.\\n2. Use subnets for isolation.\\n3. Configure route tables properly.\\n4. Implement security groups and NACLs.',
      'readTime': '10 min',
    },
    {
      'title': 'CloudWatch Monitoring Tips',
      'category': 'Monitoring',
      'description': 'Get the most out of CloudWatch.',
      'content': '1. Set up custom metrics for your applications.\\n2. Create alarms for critical thresholds.\\n3. Use CloudWatch Logs Insights for analysis.\\n4. Enable detailed monitoring when needed.',
      'readTime': '5 min',
    },
    {
      'title': 'DynamoDB Performance',
      'category': 'Database',
      'description': 'Optimize DynamoDB for speed and cost.',
      'content': '1. Design efficient partition keys.\\n2. Use Global Secondary Indexes wisely.\\n3. Enable auto-scaling for capacity.\\n4. Implement caching with DAX.',
      'readTime': '9 min',
    },
  ];



  List<Map<String, String>> get _filteredArticles {
    return _articles.where((article) {
      // Filter by category (Global) - Accept both 'All' and 'Todos' as "show all"
      if (widget.selectedCategory != 'All' && 
          widget.selectedCategory != 'Todos' && 
          article['category'] != widget.selectedCategory) {
        return false;
      }
      
      // Filter by search (Global)
      if (widget.searchQuery.isNotEmpty) {
        final query = widget.searchQuery.toLowerCase();
        return article['title']!.toLowerCase().contains(query) ||
            article['description']!.toLowerCase().contains(query) ||
            article['category']!.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredArticles;

    return Column(
      children: [
        // Toolbar REMOVED (Global)
        
        // Content
        
        // Content
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No articles found',
                        style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : (widget.viewType == 'grid' || widget.viewType == 'dashboard')
                  ? _buildGridView(filtered, colorScheme)
                  : _buildListView(filtered, colorScheme),
        ),
      ],
    );
  }



  Widget _buildGridView(List<Map<String, String>> articles, ColorScheme colorScheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: articles.length,
      itemBuilder: (context, index) => _buildGridCard(articles[index], colorScheme),
    );
  }

  Widget _buildListView(List<Map<String, String>> articles, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: articles.length,
      itemBuilder: (context, index) => _buildListCard(articles[index], colorScheme),
    );
  }

  Widget _buildGridCard(Map<String, String> article, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showArticleDetails(context, article),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  article['category']!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.article_outlined,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                article['title']!,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Description
              Expanded(
                child: Text(
                  article['description']!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Read Time
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    article['readTime']!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward, size: 16, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(Map<String, String> article, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showArticleDetails(context, article),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.article_outlined,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article['category']!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time, size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          article['readTime']!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article['title']!,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article['description']!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showArticleDetails(BuildContext context, Map<String, String> article) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article['category']!,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['title']!,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            article['readTime']!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        article['description']!,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      Text(
                        article['content']!,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // _searchController.dispose();
    super.dispose();
  }
}
