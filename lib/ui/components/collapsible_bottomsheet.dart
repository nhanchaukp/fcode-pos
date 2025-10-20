import 'package:fcode_pos/data/models/log.dart';
import 'package:fcode_pos/data/models/project_info.dart';
import 'package:fcode_pos/ui/components/responsive_layout.dart';
import 'package:fcode_pos/ui/components/single_wrap.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';

class CollapsibleBottomSheet extends StatefulWidget {
  final String title;
  final List<Log> logs;
  final ProjectInfo projectInfo;

  const CollapsibleBottomSheet({
    super.key,
    this.title = "Logs",
    required this.logs,
    required this.projectInfo,
  });

  @override
  State<CollapsibleBottomSheet> createState() => _CollapsibleBottomSheetState();
}

class _CollapsibleBottomSheetState extends State<CollapsibleBottomSheet> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEDEDF0), width: 1),
        ),
      ),
      child: SingleWrap(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => isExpanded = !isExpanded),
                  behavior: HitTestBehavior.opaque,
                  // Captures taps on empty spaces too
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title & Logs Count
                        Row(
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF56565C),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.applyOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.logs.length.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF56565C),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Expand/Collapse Icon
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF97979B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: isExpanded
                  ? MediaQuery.of(context).size.height * 0.575
                  : 0, // Expandable height
              child: isExpanded
                  ? SingleChildScrollView(
                      child: LogsBottomSheet(
                        logs: widget.logs,
                        projectInfo: widget.projectInfo,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class LogsBottomSheet extends StatelessWidget {
  final List<Log> logs;
  final ProjectInfo projectInfo;

  const LogsBottomSheet({
    super.key,
    required this.logs,
    required this.projectInfo,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        smallDeviceLayout: Column(
          children: [
            // Project Info Section
            ProjectSection(projectInfo: projectInfo),

            // Logs Table
            logs.isEmpty
                ? const EmptyLogsSection()
                : Column(
                    children: [
                      LogsTableHeader(),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          return LogsTableRow(
                            log: logs[index],
                            needsScroll: true,
                          );
                        },
                      ),
                    ],
                  ),
          ],
        ),
        largeDeviceLayout: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: ProjectSection(projectInfo: projectInfo),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFEDEDF0),
              ),
              Expanded(
                flex: 2,
                child: logs.isEmpty
                    ? EmptyLogsSection()
                    : Column(
                        children: [
                          LogsTableHeader(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: logs.length,
                              itemBuilder: (context, index) => LogsTableRow(
                                log: logs[index],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ));
  }
}

class ProjectSection extends StatelessWidget {
  final ProjectInfo projectInfo;

  const ProjectSection({
    super.key,
    required this.projectInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Background & Dividers
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFB),
            border: Border.symmetric(
              horizontal: BorderSide(color: Color(0xFFEDEDF0), width: 1),
            ),
          ),
          child: const Text(
            "Project",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF97979B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Grid Layout for Project Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ProjectRow(title: "Endpoint", value: projectInfo.endpoint),
                  ProjectRow(title: "Project ID", value: projectInfo.projectId),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// **Reusable Row for Project Details**
class ProjectRow extends StatelessWidget {
  final String title;
  final String value;

  const ProjectRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF97979B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF56565C),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class EmptyLogsSection extends StatelessWidget {
  const EmptyLogsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Background & Dividers
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFB),
            border: Border.symmetric(
              horizontal: BorderSide(color: Color(0xFFEDEDF0), width: 1),
            ),
          ),
          child: const Text(
            "Logs",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF97979B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Empty State Message
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "There are no logs to show",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF56565C),
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class LogsTableHeader extends StatelessWidget {
  const LogsTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFB),
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFEDEDF0), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _columns.map((column) {
            return SizedBox(
              width: column.$2, // Fixed width per column
              child: Text(
                column.$1,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF97979B),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Column definitions (Equivalent to the `columns` list in Compose)
const List<(String, double)> _columns = [
  ("Date", 150),
  ("Status", 80),
  ("Method", 100),
  ("Path", 125),
  ("Response", 300),
];

class LogsTableRow extends StatelessWidget {
  final Log log;
  final bool needsScroll;

  const LogsTableRow({
    super.key,
    required this.log,
    this.needsScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 16, left: 16, bottom: 8),
          child: needsScroll
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildTextCell(log.date, _columns[0].$2, monospace: true),
                      _buildStatusCell(log.status.toString(), _columns[1].$2),
                      _buildTextCell(log.method, _columns[2].$2,
                          monospace: true),
                      _buildTextCell(log.path, _columns[3].$2, monospace: true),
                      _buildResponseCell(log.response, _columns[4].$2),
                    ],
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildTextCell(log.date, _columns[0].$2, monospace: true),
                    _buildStatusCell(log.status.toString(), _columns[1].$2),
                    _buildTextCell(log.method, _columns[2].$2, monospace: true),
                    _buildTextCell(log.path, _columns[3].$2, monospace: true),
                    Expanded(
                        child:
                            _buildResponseCell(log.response, _columns[4].$2)),
                  ],
                ),
        ),
        const Divider(color: Color(0xFFEDEDF0), thickness: 1),
      ],
    );
  }

  /// Builds a standard text cell.
  Widget _buildTextCell(String text, double width, {bool monospace = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontFamily: monospace ? 'monospace' : null,
          color: const Color(0xFF56565C),
        ),
      ),
    );
  }

  /// Builds the status cell with dynamic colors.
  Widget _buildStatusCell(String status, double width) {
    final isSuccess = int.tryParse(status) != null &&
        (200 <= int.parse(status) && int.parse(status) <= 399);

    final color = isSuccess ? const Color(0xFF0A714F) : const Color(0xFFB31212);

    final bgColor =
        isSuccess ? const Color(0x4010B981) : const Color(0x40FF453A);

    return SizedBox(
      width: width,
      child: SingleWrap(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the response cell with a gray background.
  Widget _buildResponseCell(String response, double width) {
    return SingleWrap(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.applyOpacity(0.25),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Tooltip(
          message: response.replaceAll(". ", ".\n"),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              response.length >= 50 ? response.substring(0, 50) : response,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF56565C),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
