import 'package:zofa_client/constant.dart';

class RateAppScreen extends StatelessWidget {
  const RateAppScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Text('Notifications Page'),
        ),
      ),
    );
  }
}
