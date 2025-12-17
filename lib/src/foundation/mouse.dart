class IMouse {
  IMouse(this.x, this.y, this.z, this.w);
  double x, y, z, w;
  // copyWith
  IMouse copyWith({double? x, double? y, double? z, double? w}) {
    return IMouse(
      x ?? this.x,
      y ?? this.y,
      z ?? this.z,
      w ?? this.w,
    );
  }
}
