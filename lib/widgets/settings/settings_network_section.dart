import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/settings_service.dart';
import '../flow/flow_components.dart';
import 'settings_shared.dart';

class SettingsNetworkSection extends StatefulWidget {
  const SettingsNetworkSection({super.key, required this.settings});

  final SettingsService settings;

  @override
  State<SettingsNetworkSection> createState() => _SettingsNetworkSectionState();
}

class _SettingsNetworkSectionState extends State<SettingsNetworkSection> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.settings.proxyHost);
    _portController =
        TextEditingController(text: widget.settings.proxyPort.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.settings.proxyEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.vpn_key_outlined,
          title: 'HTTP 代理',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '启用后，所有网络请求（词典查询、图片词典、AI 等）将通过代理发送。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: (v) => widget.settings.setProxyEnabled(v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ResponsiveSettingsGrid(
                children: [
                  FlowTextField(
                    controller: _hostController,
                    enabled: enabled,
                    decoration: const InputDecoration(
                      labelText: '主机地址',
                      hintText: '127.0.0.1',
                      prefixIcon: Icon(Icons.dns_outlined, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => widget.settings.setProxyHost(v),
                  ),
                  FlowTextField(
                    controller: _portController,
                    enabled: enabled,
                    decoration: const InputDecoration(
                      labelText: '端口',
                      hintText: '7890',
                      prefixIcon: Icon(Icons.numbers_outlined, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final port = int.tryParse(v);
                      if (port != null && port > 0 && port <= 65535) {
                        widget.settings.setProxyPort(port);
                      }
                    },
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(height: 12),
                SettingsStatusLine(
                  icon: Icons.check_circle_outline,
                  text:
                      '当前代理：${widget.settings.proxyHost}:${widget.settings.proxyPort}',
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
