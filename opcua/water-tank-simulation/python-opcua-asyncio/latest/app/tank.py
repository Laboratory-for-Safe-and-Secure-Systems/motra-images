import random


class Tank:
    def __init__(self,
                 name: str,
                 volume_m3: float,
                 height_mm: float,
                 max_lvl_mm: float,
                 min_lvl_mm: float,
                 lvl_mm: float,
                 sim_step_s: float =.1):
        self.name = name
        self.volume_l = 1_000 * volume_m3
        self.height_mm = height_mm
        self.max_lvl_mm = max_lvl_mm
        self.min_lvl_mm = min_lvl_mm
        self.lvl_mm = lvl_mm
        self.sim_step = sim_step_s
        self.update_fill_pct()

    def update_fill_pct(self):
        """Update fill percentage from current fill level."""
        self.fill_pct = 100 * self.lvl_mm / self.height_mm

    def mm_to_l(self, lvl_mm: float) -> float:
        """Calculate fill volume in liters from fill level in mm."""
        return self.volume_l * (lvl_mm / self.height_mm)

    def l_to_mm(self, volume_l: float) -> float:
        """Calculate fill level in mm from fill volume in liters."""
        return self.height_mm * (volume_l / self.volume_l)

    def calculate_new_fill_level(self, inflows: list[float], outflows: list[float]) -> float:
        """Update tank fill level based on inflows and outflows (both in liters/s)."""

        total_inflow = sum(inflows)
        total_outflow = sum(outflows)

        current_volume_l = self.mm_to_l(self.lvl_mm)
        new_volume_l = current_volume_l + (total_inflow - total_outflow) * self.sim_step

        new_lvl_mm = self.l_to_mm(new_volume_l)
        self.lvl_mm = new_lvl_mm
        self.update_fill_pct()

        # Add random sensor noise
        return new_lvl_mm + random.gauss(0, 10)



