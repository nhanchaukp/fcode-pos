import 'package:fcode_pos/data/models/status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that displays the current connection status and allows the user to send a ping.
class ConnectionStatusView extends StatelessWidget {
  final Status status;
  final VoidCallback onButtonClick;

  const ConnectionStatusView({
    super.key,
    required this.status,
    required this.onButtonClick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 80,
            child: AnimatedSwitcher(
              duration: kThemeAnimationDuration,
              child: _buildStatusContent(),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: status == Status.loading ? 0.0 : 1.0,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              // onPressed: status == Status.loading ? null : _sendPing,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFD366E),
                disabledBackgroundColor: const Color(0xFFEDEDF0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(0, 32),
                elevation: 0,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                child: Text(
                  "Send a ping",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the status message UI dynamically.
  Widget _buildStatusContent() {
    return Align(
      key: ValueKey(status),
      alignment: Alignment.center,
      child: switch (status) {
        Status.loading => _buildLoadingIndicator(),
        Status.success => _buildSuccessMessage(),
        Status.error => _buildIdleMessage(),
        Status.idle || Status.error => _buildIdleMessage(),
      },
    );
  }

  /// Loading State
  Widget _buildLoadingIndicator() {
    return Row(
      key: const ValueKey(Status.loading),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          "Waiting for connection...",
          style: TextStyle(
            fontSize: 14,
            height: 19.6 / 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2D2D31),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  /// Success State
  Widget _buildSuccessMessage() {
    return Column(
      key: const ValueKey(Status.success),
      children: const [
        Text(
          "Congratulations!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2D2D31),
          ),
        ),
        SizedBox(height: 8),
        Text(
          "You connected your app successfully.",
          style: TextStyle(
            fontSize: 14,
            height: 19.6 / 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF56565C),
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Idle State
  Widget _buildIdleMessage() {
    return Column(
      key: const ValueKey(Status.idle),
      children: const [
        Text(
          "Check connection",
          style: TextStyle(
            fontSize: 24,
            height: 28.8 / 24,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2D2D31),
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Send a ping to verify the connection.",
          style: TextStyle(
            fontSize: 14,
            height: 19.6 / 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF56565C),
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
