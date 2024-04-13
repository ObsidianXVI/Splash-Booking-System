part of splash;

ButtonStyle splashButtonStyle() => ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.hovered)) {
          return red.withOpacity(0.4);
        } else if (states.contains(MaterialState.pressed)) {
          return red.withOpacity(0.6);
        } else {
          return red.withOpacity(0.1);
        }
      }),
      foregroundColor: const MaterialStatePropertyAll(red),
    );
