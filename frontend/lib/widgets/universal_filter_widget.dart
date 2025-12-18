import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FilterCondition {
  contains,
  notContains,
  startsWith,
  endsWith,
  exactMatch,
  containsNumbers,
  containsLetters,
  onlyNumbers,
  containsSymbol,
  regex,
}

enum FilterConnector {
  and,
  or,
}

class FilterBlock {
  FilterCondition condition;
  String value;
  FilterConnector connector;

  FilterBlock({
    this.condition = FilterCondition.contains,
    this.value = '',
    this.connector = FilterConnector.and,
  });
}

class UniversalFilterWidget extends StatefulWidget {
  final Function(String) onFilterChanged;

  const UniversalFilterWidget({super.key, required this.onFilterChanged});

  @override
  State<UniversalFilterWidget> createState() => _UniversalFilterWidgetState();
}

class _UniversalFilterWidgetState extends State<UniversalFilterWidget> {
  final List<FilterBlock> _filters = [FilterBlock()];

  void _updateFilter() {
    String command = '';
    for (int i = 0; i < _filters.length; i++) {
      final filter = _filters[i];
      String pattern = '';

      switch (filter.condition) {
        case FilterCondition.contains:
          pattern = '.*${filter.value}.*';
          break;
        case FilterCondition.notContains:
          pattern = '.*${filter.value}.*';
          break;
        case FilterCondition.startsWith:
          pattern = '^${filter.value}.*';
          break;
        case FilterCondition.endsWith:
          pattern = '.*${filter.value}\$';
          break;
        case FilterCondition.exactMatch:
          pattern = '^${filter.value}\$';
          break;
        case FilterCondition.containsNumbers:
          pattern = filter.value.isEmpty ? '.*[0-9]+.*' : '.*${filter.value}.*[0-9]+.*';
          break;
        case FilterCondition.containsLetters:
          pattern = '.*[A-Za-z]+.*';
          break;
        case FilterCondition.onlyNumbers:
          pattern = '^[0-9]+\$';
          break;
        case FilterCondition.containsSymbol:
          pattern = '.*[^A-Za-z0-9 ].*';
          break;
        case FilterCondition.regex:
          pattern = filter.value;
          break;
      }

      String grepCmd = 'grep -E "$pattern"';
      if (filter.condition == FilterCondition.notContains) {
        grepCmd = 'grep -Ev "$pattern"';
      }

      if (i == 0) {
        command += grepCmd;
      } else {
        final prevConnector = _filters[i - 1].connector;
        if (prevConnector == FilterConnector.and) {
          command += ' | $grepCmd';
        } else {
          command += ' || $grepCmd';
        }
      }
    }
    widget.onFilterChanged(command);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_alt_outlined, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Refinar Resultados',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Filtre a saída do comando para encontrar o que precisa.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (_filters.length > 1 || _filters[0].value.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filters.clear();
                      _filters.add(FilterBlock());
                      _updateFilter();
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Limpar'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),

        // Filters List
        ..._filters.asMap().entries.map((entry) {
          int index = entry.key;
          FilterBlock filter = entry.value;
          bool isLast = index == _filters.length - 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Condition Dropdown with Icons
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<FilterCondition>(
                              value: filter.condition,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
                              style: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurface),
                              items: FilterCondition.values.map((c) {
                                String label = '';
                                IconData icon = Icons.circle;
                                Color? iconColor;

                                switch (c) {
                                  case FilterCondition.contains: 
                                    label = 'Contém'; 
                                    icon = Icons.search;
                                    iconColor = Colors.blue;
                                    break;
                                  case FilterCondition.notContains: 
                                    label = 'Não contém'; 
                                    icon = Icons.block;
                                    iconColor = Colors.red;
                                    break;
                                  case FilterCondition.startsWith: 
                                    label = 'Começa com'; 
                                    icon = Icons.first_page;
                                    break;
                                  case FilterCondition.endsWith: 
                                    label = 'Termina com'; 
                                    icon = Icons.last_page;
                                    break;
                                  case FilterCondition.exactMatch: 
                                    label = 'Igual a'; 
                                    icon = Icons.check_circle_outline;
                                    break;
                                  case FilterCondition.containsNumbers: 
                                    label = 'Tem números'; 
                                    icon = Icons.numbers;
                                    break;
                                  case FilterCondition.containsLetters: 
                                    label = 'Tem letras'; 
                                    icon = Icons.abc;
                                    break;
                                  case FilterCondition.onlyNumbers: 
                                    label = 'Só números'; 
                                    icon = Icons.onetwothree;
                                    break;
                                  case FilterCondition.containsSymbol: 
                                    label = 'Tem símbolo'; 
                                    icon = Icons.emoji_symbols;
                                    break;
                                  case FilterCondition.regex: 
                                    label = 'Avançado (Regex)'; 
                                    icon = Icons.code;
                                    break;
                                }
                                return DropdownMenuItem(
                                  value: c, 
                                  child: Row(
                                    children: [
                                      Icon(icon, size: 16, color: iconColor ?? colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 8),
                                      Text(label),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  filter.condition = val!;
                                  _updateFilter();
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Value Input
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: filter.value,
                          decoration: InputDecoration(
                            hintText: 'Digite o valor...',
                            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                            isDense: true,
                            filled: true,
                            fillColor: colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                          ),
                          style: GoogleFonts.inter(fontSize: 13),
                          onChanged: (val) {
                            filter.value = val;
                            _updateFilter();
                          },
                        ),
                      ),
                      // Remove Button (if not only one)
                      if (_filters.length > 1)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: colorScheme.onSurfaceVariant,
                          tooltip: 'Remover filtro',
                          onPressed: () {
                            setState(() {
                              _filters.removeAt(index);
                              _updateFilter();
                            });
                          },
                        ),
                    ],
                  ),
                ),
                
                // Connector (AND/OR) - Show below item if not last
                if (!isLast)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildConnectorOption(filter, FilterConnector.and, 'E (AND)', colorScheme),
                        const SizedBox(width: 16),
                        _buildConnectorOption(filter, FilterConnector.or, 'OU (OR)', colorScheme),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),

        // Add Button
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _filters.add(FilterBlock());
                _updateFilter();
              });
            },
            icon: const Icon(Icons.add_circle, size: 18),
            label: const Text('Adicionar Condição'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectorOption(FilterBlock filter, FilterConnector connector, String label, ColorScheme colorScheme) {
    final isSelected = filter.connector == connector;
    return InkWell(
      onTap: () {
        setState(() {
          filter.connector = connector;
          _updateFilter();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: colorScheme.primary.withOpacity(0.5)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 14,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
