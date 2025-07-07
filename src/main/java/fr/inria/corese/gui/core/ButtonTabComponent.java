package fr.inria.corese.gui.core;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;

import javax.swing.AbstractButton;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTabbedPane;
import javax.swing.plaf.basic.BasicButtonUI;

/**
 * Creates the closing cross on tabs. Contains a JButton to close the tab and a JLabel to show the
 * text when hovering over the button
 */
public class ButtonTabComponent extends JPanel {

    private final JTabbedPane pane;

    /**
     * Adds the closing button to the tab
     *
     * @param coreseFrame
     */
    public ButtonTabComponent(final JTabbedPane pane, final MainFrame coreseFrame) {
        super(new FlowLayout(FlowLayout.LEFT, 0, 0));
        if (pane == null) {
            throw new NullPointerException("TabbedPane is null");
        }
        this.pane = pane;
        setOpaque(false);

        JLabel label =
                new JLabel() {
                    public String getText() {
                        int i = pane.indexOfTabComponent(ButtonTabComponent.this);
                        if (i != -1) {
                            return pane.getTitleAt(i);
                        }
                        return null;
                    }
                };

        add(label);
        // espace le bouton et le label
        label.setBorder(BorderFactory.createEmptyBorder(0, 0, 0, 5));
        // le bouton
        JButton button = new TabButton(coreseFrame);
        add(button);
        setBorder(BorderFactory.createEmptyBorder(2, 0, 0, 0));
    }

    public class TabButton extends JButton implements ActionListener {

        public TabButton(final MainFrame coreseFrame) {
            int size = 17;
            setPreferredSize(new Dimension(size, size));
            setToolTipText("close this tab");
            // Apparence du bouton
            setUI(new BasicButtonUI());
            // Pour la trensparence
            setContentAreaFilled(false);
            setFocusable(false);
            setBorder(BorderFactory.createEtchedBorder());
            setBorderPainted(false);
            // Même listener pour tous les boutons
            addMouseListener(buttonMouseListener);
            setRolloverEnabled(true);
            ActionListener closeTab =
                    new ActionListener() {
                        public void actionPerformed(ActionEvent l_Event) {
                            int i = pane.indexOfTabComponent(ButtonTabComponent.this);
                            if (i != -1) {

                                // Si l'on ferme le dernier onglet avant le "+" sachant qu'il est
                                // sélectionné on sélectionne l'onglet précédent avant de le fermer
                                if ((coreseFrame.getConteneurOnglets().getSelectedIndex()
                                                == coreseFrame
                                                                .getConteneurOnglets()
                                                                .getComponentCount()
                                                        - 3)
                                        && i
                                                == coreseFrame
                                                        .getConteneurOnglets()
                                                        .getSelectedIndex()) {
                                    coreseFrame
                                            .getConteneurOnglets()
                                            .setSelectedIndex(coreseFrame.getSelected() - 1);
                                } // Sinon le même reste sélectionné
                                else {
                                    coreseFrame
                                            .getConteneurOnglets()
                                            .setSelectedIndex(coreseFrame.getSelected());
                                }
                                // On supprime l'onglet
                                pane.remove(i);
                            }
                        }
                    };
            addActionListener(closeTab);
        }

        public void updateUI() {}

        // dessine la croix
        protected void paintComponent(Graphics g) {
            super.paintComponent(g);
            Graphics2D g2 = (Graphics2D) g.create();
            if (getModel().isPressed()) {
                g2.translate(1, 1);
            }
            g2.setStroke(new BasicStroke(2));
            g2.setColor(Color.BLACK);
            if (getModel().isRollover()) {
                g2.setColor(Color.RED);
            }
            int delta = 6;
            g2.drawLine(delta, delta, getWidth() - delta - 1, getHeight() - delta - 1);
            g2.drawLine(getWidth() - delta - 1, delta, delta, getHeight() - delta - 1);
            g2.dispose();
        }

        public void actionPerformed(ActionEvent e) {
            // Pour éviter une erreur ...
        }
    }

    private static final MouseListener buttonMouseListener =
            new MouseAdapter() {
                public void mouseEntered(MouseEvent e) {
                    Component component = e.getComponent();
                    if (component instanceof AbstractButton) {
                        AbstractButton button = (AbstractButton) component;
                        button.setBorderPainted(true);
                    }
                }

                public void mouseExited(MouseEvent e) {
                    Component component = e.getComponent();
                    if (component instanceof AbstractButton) {
                        AbstractButton button = (AbstractButton) component;
                        button.setBorderPainted(false);
                    }
                }
            };
}
