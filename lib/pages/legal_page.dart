import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';

class LegalPage extends StatelessWidget {
  final bool isPrivacy;

  const LegalPage({super.key, this.isPrivacy = true});

  static const _privacyContent = '''
隐私政策

更新日期：2026年5月12日
生效日期：2026年5月12日

心晴日记（以下简称"我们"）深知个人信息对你的重要性，我们将按照法律法规的规定，保护你的个人信息安全。

一、我们收集的信息

1. 账号信息：手机号码、用户名、密码（加密存储）
2. 心情记录：你主动记录的情绪、标签、碎碎念文字
3. 日记内容：你主动撰写的日记
4. 位置信息：用于获取你所在城市的天气数据
5. 设备信息：设备型号、操作系统版本（用于适配优化）

二、信息存储

1. 账号、心情记录、日记、社交关系存储在云端服务器
2. 你上传的照片仅存储在你的手机本地，我们不会上传或访问
3. 你的密码通过加密算法存储，我们无法逆向获取

三、信息安全

1. 我们采用行业标准的安全措施保护你的信息
2. 所有网络传输使用加密协议
3. API密钥存储在服务器环境变量中，不会写入App代码

四、信息使用

1. 天气数据：根据你的位置信息获取当地天气
2. AI回应：你的心情数据会发送至AI服务生成回应（不包含个人身份信息）
3. 推送通知：根据你的签到和心情记录发送早晚安提醒
4. 我们不会将你的个人信息出售给第三方

五、你的权利

1. 你可以在设置中随时修改或删除你的个人信息
2. 你可以导出你的心情记录数据
3. 你可以随时注销账号，所有云端数据将被永久删除
4. 你可以在手机系统设置中撤回已授权的权限

六、未成年人保护

如果你未满18周岁，请在监护人指导下使用本应用。

七、政策更新

我们可能会适时更新本隐私政策。更新后会在App内通知你。

八、联系我们

如有任何疑问，请联系我们。
''';

  static const _termsContent = '''
用户协议

更新日期：2026年5月12日
生效日期：2026年5月12日

欢迎使用心晴日记！请仔细阅读本协议。

一、服务说明

心晴日记是一款天气+心情记录应用，提供情绪记录、天气查看、日记、轻社交等功能。

二、账号管理

1. 你需要使用手机号码注册账号
2. 你应当对账号下的所有行为负责
3. 请妥善保管你的账号密码，不要透露给他人
4. 如发现账号异常，请立即联系我们

三、使用规范

你承诺不会利用本应用从事以下行为：
1. 发布违法、有害、侮辱、诽谤、骚扰等不良信息
2. 冒充他人或伪造身份
3. 利用技术手段干扰App正常运行
4. 批量注册账号或恶意刷数据
5. 其他违反法律法规的行为

四、内容规范

1. 你在树洞发布的匿名留言不会显示你的身份信息
2. 我们会对留言内容进行敏感词过滤
3. 我们有权删除违规内容并限制违规账号的功能

五、知识产权

1. App的界面设计、代码、图标、动画等知识产权归我们所有
2. 你创作的心情记录、日记等内容的知识产权归你所有

六、免责声明

1. 天气数据来自第三方服务，我们不对其准确性做绝对保证
2. AI回应由AI模型自动生成，仅供参考
3. 因不可抗力导致的服务中断，我们不承担责任

七、协议修改

我们可能会适时修改本协议。修改后会在App内通知你。继续使用即视为同意修改后的协议。

八、法律适用

本协议适用中华人民共和国法律。
''';

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final title = isPrivacy ? '隐私政策' : '用户协议';
    final content = isPrivacy ? _privacyContent : _termsContent;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: theme.textPrimary)),
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(content,
              style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 14,
                  height: 1.8)),
        ),
      ),
    );
  }
}
