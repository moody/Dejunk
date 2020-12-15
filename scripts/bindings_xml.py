from xml.dom import minidom
from html import unescape
import os
import sys

XML_PATH = "Bindings.xml"


class BindingsDocument:
    def __init__(self):
        self.root = minidom.Document()
        self.bindings = self.root.createElement("Bindings")
        self.root.appendChild(self.bindings)

    def add(self, name: str, lua: [str], header: str = None):
        binding = self.root.createElement("Binding")
        binding.setAttribute("name", name)
        if header is not None:
            binding.setAttribute("header", header)
        binding.setAttribute("category", "BINDING_CATEGORY_DEJUNK")
        for line in lua:
            binding.appendChild(self.root.createTextNode(line))
        self.bindings.appendChild(binding)

    def write(self):
        with open(XML_PATH, "w") as f:
            f.write(unescape(self.root.toprettyxml(indent="  ")))


def generate(classic: bool = False):
    bindings = BindingsDocument()

    # Toggle options frame.
    bindings.add(
        name="DEJUNK_TOGGLE_OPTIONS_FRAME",
        lua=["DejunkBindings_ToggleOptionsFrame()"],
        header="DEJUNK_HEADER_GENERAL",
    )

    # Toggle sell frame.
    bindings.add(
        name="DEJUNK_TOGGLE_SELL_FRAME", lua=["DejunkBindings_ToggleSellFrame()"]
    )

    # Toggle destroy frame.
    bindings.add(
        name="DEJUNK_TOGGLE_DESTROY_FRAME", lua=["DejunkBindings_ToggleDestroyFrame()"],
    )

    # Open lootables.
    bindings.add(name="DEJUNK_OPEN_LOOTABLES", lua=["DejunkBindings_OpenLootables()"])

    # Start selling.
    bindings.add(
        name="DEJUNK_START_SELLING",
        lua=["DejunkBindings_StartSelling()"],
        header="DEJUNK_HEADER_SELL",
    )

    # Sell next item.
    bindings.add(name="DEJUNK_SELL_NEXT_ITEM", lua=["DejunkBindings_SellNextItem()"])

    # Add/rem sell inclusions.
    bindings.add(
        name="DEJUNK_ADD_INCLUSIONS",
        lua=['DejunkBindings_AddToList("sell", "inclusions")'],
    )
    bindings.add(
        name="DEJUNK_REM_INCLUSIONS",
        lua=['DejunkBindings_RemoveFromList("sell", "inclusions")'],
    )

    # Add/rem sell exclusions.
    bindings.add(
        name="DEJUNK_ADD_EXCLUSIONS",
        lua=['DejunkBindings_AddToList("sell", "exclusions")'],
    )
    bindings.add(
        name="DEJUNK_REM_EXCLUSIONS",
        lua=['DejunkBindings_RemoveFromList("sell", "exclusions")'],
    )

    if classic:
        # Start destroying.
        bindings.add(
            name="DEJUNK_START_DESTROYING",
            lua=["DejunkBindings_StartDestroying()"],
            header="DEJUNK_HEADER_DESTROY",
        )

        # Destroy next item.
        bindings.add(
            name="DEJUNK_DESTROY_NEXT_ITEM", lua=["DejunkBindings_DestroyNextItem()"],
        )
    else:
        # Destroy next item.
        bindings.add(
            name="DEJUNK_DESTROY_NEXT_ITEM",
            lua=["DejunkBindings_DestroyNextItem()"],
            header="DEJUNK_HEADER_DESTROY",
        )

    # Add/rem destroy inclusions.
    bindings.add(
        name="DEJUNK_ADD_DESTROYABLES",
        lua=['DejunkBindings_AddToList("destroy", "inclusions")'],
    )
    bindings.add(
        name="DEJUNK_REM_DESTROYABLES",
        lua=['DejunkBindings_RemoveFromList("destroy", "inclusions")'],
    )

    # Add/rem destroy exclusions.
    bindings.add(
        name="DEJUNK_ADD_UNDESTROYABLES",
        lua=['DejunkBindings_AddToList("destroy", "exclusions")'],
    )
    bindings.add(
        name="DEJUNK_REM_UNDESTROYABLES",
        lua=['DejunkBindings_RemoveFromList("destroy", "exclusions")'],
    )

    # Write file.
    bindings.write()


if __name__ == "__main__":
    if os.path.exists(XML_PATH):
        os.remove(XML_PATH)

    if len(sys.argv) >= 2 and sys.argv[1] == "-c":
        generate(classic=True)
    else:
        generate()
