part of splash;

typedef RefreshFn = void Function();
typedef DismissFn = void Function();

abstract class ModalView<T> extends StatefulWidget {
  final String title;
  final void Function(T) returnValue;

  const ModalView({
    required this.title,
    required this.returnValue,
    super.key,
  });

  @override
  State<ModalView> createState();
}

abstract class ModalViewState<T extends ModalView> extends State<T> {
  void dismiss(BuildContext context) =>
      mounted ? Navigator.of(context).pop() : null;

  Widget modalScaffold({required Widget child}) {
    return Material(
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(widget.title),
                  const SizedBox(height: 40),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
