import 'package:flutter/material.dart';
import 'package:user_interface/MAIN%20UTILS/app_sizes.dart';


class BottomNavBTN extends StatelessWidget {
  final Function(int) onPressed;
  final IconData icon;
  final int index;
  final int currentIndex;

  const BottomNavBTN({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.index,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    AppSizes().init(context);
    return InkWell(
      onTap: () {
        onPressed(index);
      },
       splashColor: Colors.transparent,   
      highlightColor: Colors.transparent, 
      hoverColor: Colors.transparent,
      child: Container(
        height: 70,
        width: 70,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            (currentIndex == index)
                ? Positioned(
                    left: 15,
                    bottom: 3,
                    child: Icon(
                      icon,
                      color: Colors.black,
                      size: 50,
                    ),
                  )
                : Container(),
            AnimatedOpacity(
              opacity: (currentIndex == index) ? 1 : 0.2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              child: Icon(
                icon,
                color: Colors.indigoAccent,
                size: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
