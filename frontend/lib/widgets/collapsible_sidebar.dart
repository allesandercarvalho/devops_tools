import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/navigation_model.dart';
import '../../services/supabase_service.dart';
import 'dependency_check_dialog.dart';

class CollapsibleSidebar extends StatefulWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final String? selectedToolId;
  final Function(int index, String? toolId) onItemSelected;

  const CollapsibleSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.selectedToolId,
    required this.onItemSelected,
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  bool _isCollapsed = false;
  final Map<String, bool> _expandedGroups = {};
  String? _hoveredItemId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final supabaseService = Provider.of<SupabaseService>(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuint,
      width: _isCollapsed ? 72 : 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withOpacity(0.95),
            colorScheme.surfaceContainerHighest.withOpacity(0.9),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: colorScheme.primary.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(10, 0),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            children: [
              // Header
              _buildHeader(colorScheme),

              // Navigation Items
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: _isCollapsed ? 8 : 16),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    return _buildNavigationItem(context, widget.items[index], index, colorScheme);
                  },
                ),
              ),

              // Footer
              _buildFooter(context, supabaseService, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      height: 90, // Slightly shorter
      padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 0 : 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerHighest.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.developer_board,
              color: colorScheme.onPrimary,
              size: 24,
            ),
          ),
          if (!_isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'DevOps Tools',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'CLI HUB PRO',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationItem(BuildContext context, NavigationItem item, int index, ColorScheme colorScheme) {
    final isSelected = widget.selectedIndex == index;

    if (_isCollapsed) {
      return _buildCollapsedItem(item, index, isSelected, colorScheme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.tertiary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withOpacity(0.3),
                          colorScheme.tertiaryContainer.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.title.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          _buildLeafItem(item, index, isSelected, colorScheme),

        if (item.children.isNotEmpty)
          ...item.children.asMap().entries.map((entry) => _buildGroup(entry.value, index, colorScheme, entry.key)),
      ],
    );
  }

  Widget _buildLeafItem(NavigationItem item, int index, bool isSelected, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItemId = item.title),
        onExit: (_) => setState(() => _hoveredItemId = null),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_hoveredItemId == item.title && !isSelected ? 1.02 : 1.0),
          decoration: BoxDecoration(
            color: isSelected 
                ? colorScheme.primary 
                : _hoveredItemId == item.title 
                    ? colorScheme.surfaceContainerHighest.withOpacity(0.5) 
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected ? [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: Icon(
              item.icon,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            title: Text(
              item.title,
              style: GoogleFonts.inter(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => widget.onItemSelected(index, null),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedItem(NavigationItem item, int index, bool isSelected, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tooltip(
        message: item.title,
        preferBelow: false,
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(color: colorScheme.onInverseSurface, fontSize: 12),
        child: InkWell(
          onTap: () {
            setState(() => _isCollapsed = false);
            widget.onItemSelected(index, null);
          },
          borderRadius: BorderRadius.circular(16),
          child: Center( // Ensure centering
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, // Smaller fixed width
              height: 44, // Smaller fixed height
              decoration: BoxDecoration(
                color: isSelected 
                    ? colorScheme.primary 
                    : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Icon(
                item.icon,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(NavigationGroup group, int index, ColorScheme colorScheme, int groupIndex) {
    final groupKey = group.title;
    final isExpanded = _expandedGroups[groupKey] ?? false;
    
    // Color palette for group icons - same as submenu items
    final groupColors = [
      const Color(0xFF3b82f6), // Blue
      const Color(0xFF10b981), // Green
      const Color(0xFF8b5cf6), // Purple
      const Color(0xFFf59e0b), // Amber
      const Color(0xFFef4444), // Red
      const Color(0xFF06b6d4), // Cyan
      const Color(0xFFec4899), // Pink
      const Color(0xFF14b8a6), // Teal
    ];
    final groupColor = groupColors[groupIndex % groupColors.length];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isExpanded
              ? LinearGradient(
                  colors: [
                    groupColor.withOpacity(0.08),
                    groupColor.withOpacity(0.04),
                  ],
                )
              : null,
        ),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (val) => setState(() => _expandedGroups[groupKey] = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: group.icon != null 
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: isExpanded
                        ? LinearGradient(
                            colors: [groupColor.withOpacity(0.25), groupColor.withOpacity(0.15)],
                          )
                        : null,
                    color: isExpanded ? null : groupColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isExpanded
                        ? [
                            BoxShadow(
                              color: groupColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    group.icon,
                    size: 16,
                    color: groupColor,
                  ),
                )
              : null,
          title: Text(
            group.title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w600,
              color: isExpanded ? groupColor : colorScheme.onSurface,
            ),
          ),
          trailing: AnimatedRotation(
            duration: const Duration(milliseconds: 300),
            turns: isExpanded ? 0.5 : 0,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isExpanded ? groupColor : colorScheme.onSurfaceVariant,
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
          children: group.items.asMap().entries.map((entry) {
          final itemIndex = entry.key;
          final child = entry.value;
          final isChildSelected = widget.selectedToolId == child.id;
          
          // Neutral colors for submenus as requested
          final iconColor = isChildSelected 
              ? colorScheme.primary 
              : colorScheme.onSurface;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 8, left: 8),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredItemId = child.id),
              onExit: (_) => setState(() => _hoveredItemId = null),
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()
                  ..translate(_hoveredItemId == child.id && !isChildSelected ? 6.0 : 0.0)
                  ..scale(_hoveredItemId == child.id && !isChildSelected ? 1.02 : 1.0),
                decoration: BoxDecoration(
                  gradient: isChildSelected 
                      ? LinearGradient(
                          colors: [
                            colorScheme.primaryContainer.withOpacity(0.8),
                            colorScheme.tertiaryContainer.withOpacity(0.6),
                          ],
                        )
                      : _hoveredItemId == child.id
                          ? LinearGradient(
                              colors: [
                                colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                colorScheme.surfaceContainerHigh.withOpacity(0.3),
                              ],
                            )
                          : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isChildSelected ? colorScheme.primary.withOpacity(0.4) : Colors.transparent,
                    width: isChildSelected ? 1.5 : 1,
                  ),
                  boxShadow: isChildSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isChildSelected 
                          ? iconColor.withOpacity(0.2)
                          : _hoveredItemId == child.id
                              ? iconColor.withOpacity(0.15)
                              : iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isChildSelected || _hoveredItemId == child.id
                          ? [
                              BoxShadow(
                                color: iconColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      child.icon,
                      key: ValueKey(isChildSelected),
                      size: 16,
                      color: isChildSelected 
                          ? iconColor
                          : _hoveredItemId == child.id
                              ? iconColor.withOpacity(0.9)
                              : iconColor.withOpacity(0.7),
                    ),
                  ),
                  title: Text(
                    child.title,
                    style: GoogleFonts.inter(
                      fontWeight: isChildSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isChildSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isChildSelected 
                      ? Container(
                          width: 6, 
                          height: 6, 
                          decoration: BoxDecoration(
                            color: colorScheme.primary, 
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          ),
                        ) 
                      : null,
                  onTap: () => widget.onItemSelected(index, child.id),
                ),
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, SupabaseService supabaseService, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest.withOpacity(0.4),
            colorScheme.surfaceContainerHigh.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // System Health Check
          InkWell(
            onTap: () {
               showDialog(
                context: context,
                builder: (context) => const DependencyCheckDialog(),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                   Icon(Icons.health_and_safety, size: 18, color: colorScheme.secondary),
                   if (!_isCollapsed) ...[
                      const SizedBox(width: 10),
                      Text(
                        'System Health',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      ),
                   ]
                ],
              ),
            ),
          ),

          // User Profile
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(14),
            child: Row(
              mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.tertiary],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.surface,
                    child: Text(
                      supabaseService.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: GoogleFonts.outfit(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supabaseService.currentUser?.email ?? 'User',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Pro Plan',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    color: colorScheme.error.withOpacity(0.8),
                    tooltip: 'Sign Out',
                    onPressed: () async {
                      await supabaseService.signOut();
                    },
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 12),

          // Collapse Toggle Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isCollapsed = !_isCollapsed),
              borderRadius: BorderRadius.circular(50),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isCollapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left,
                  color: colorScheme.onSurface,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
